package keeper

import (
	"context"
	"encoding/json"
	"fmt"
	"math/big"
	"strings"

	"cosmossdk.io/errors"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/common/hexutil"

	evmtypes "github.com/InjectiveLabs/injective-core/injective-chain/modules/evm/types"
	"github.com/InjectiveLabs/injective-core/injective-chain/modules/permissions/types"
)

const (
	// Method signatures for MyUSDC contract
	PausedMethod        = "paused()"
	IsBlacklistedMethod = "isBlacklisted(address)"
)

// ABI definitions for the MyUSDC contract methods we need to call
var (
	pausedMethodID        = []byte{0x5c, 0x97, 0x5a, 0xbb} // paused()
	isBlacklistedMethodID = []byte{0xfe, 0x57, 0x5a, 0x87} // isBlacklisted(address)
)

// IsERC20TokenPaused checks if an ERC20 contract is paused by calling the paused() method
func (k Keeper) IsERC20TokenPaused(ctx context.Context, contractAddr string) (bool, error) {
	if !common.IsHexAddress(contractAddr) {
		return false, fmt.Errorf("invalid contract address: %s", contractAddr)
	}

	// Prepare the call data for paused() method
	callData := pausedMethodID

	// Create EthCall request
	callArgs := map[string]interface{}{
		"to":   contractAddr,
		"data": hexutil.Encode(callData),
	}

	callArgsBytes, err := json.Marshal(callArgs)
	if err != nil {
		return false, errors.Wrap(err, "failed to marshal call args")
	}

	req := &evmtypes.EthCallRequest{
		Args:   callArgsBytes,
		GasCap: 100000, // Conservative gas cap for view functions
	}

	// Execute the call
	resp, err := k.evmKeeper.EthCall(ctx, req)
	if err != nil {
		return false, errors.Wrapf(err, "failed to call paused() on contract %s", contractAddr)
	}

	// Check if the call was successful
	if resp.Failed() {
		return false, fmt.Errorf("paused() call failed: %s", resp.VmError)
	}

	// Parse the response (boolean return value)
	if len(resp.Ret) < 32 {
		return false, fmt.Errorf("invalid response length from paused(): %d", len(resp.Ret))
	}

	// Boolean values are returned as 32-byte words with the value in the last byte
	return resp.Ret[31] != 0, nil
}

// IsERC20AddressBlacklisted checks if an address is blacklisted by calling isBlacklisted(address) method
func (k Keeper) IsERC20AddressBlacklisted(ctx context.Context, contractAddr string, userAddr sdk.AccAddress) (bool, error) {
	if !common.IsHexAddress(contractAddr) {
		return false, fmt.Errorf("invalid contract address: %s", contractAddr)
	}

	// Convert cosmos address to ethereum address
	ethAddr := common.BytesToAddress(userAddr.Bytes())

	// Prepare the call data for isBlacklisted(address) method
	callData := append(isBlacklistedMethodID, common.LeftPadBytes(ethAddr.Bytes(), 32)...)

	// Create EthCall request
	callArgs := map[string]interface{}{
		"to":   contractAddr,
		"data": hexutil.Encode(callData),
	}

	callArgsBytes, err := json.Marshal(callArgs)
	if err != nil {
		return false, errors.Wrap(err, "failed to marshal call args")
	}

	req := &evmtypes.EthCallRequest{
		Args:   callArgsBytes,
		GasCap: 100000, // Conservative gas cap for view functions
	}

	// Execute the call
	resp, err := k.evmKeeper.EthCall(ctx, req)
	if err != nil {
		return false, errors.Wrapf(err, "failed to call isBlacklisted() on contract %s", contractAddr)
	}

	// Check if the call was successful
	if resp.Failed() {
		return false, fmt.Errorf("isBlacklisted() call failed: %s", resp.VmError)
	}

	// Parse the response (boolean return value)
	if len(resp.Ret) < 32 {
		return false, fmt.Errorf("invalid response length from isBlacklisted(): %d", len(resp.Ret))
	}

	// Boolean values are returned as 32-byte words with the value in the last byte
	return resp.Ret[31] != 0, nil
}

// CheckERC20Restrictions checks both pause and blacklist restrictions for an ERC20 token
func (k Keeper) CheckERC20Restrictions(ctx context.Context, denom string, fromAddr, toAddr sdk.AccAddress) error {
	// Check if this is an ERC20 denom (format: "erc20:0x...")
	if !strings.HasPrefix(denom, "erc20:") {
		return nil // Not an ERC20 token, no restrictions to check
	}

	// Extract contract address from denom
	contractAddr := strings.TrimPrefix(denom, "erc20:")
	if !common.IsHexAddress(contractAddr) {
		return fmt.Errorf("invalid ERC20 contract address in denom: %s", contractAddr)
	}

	// Check if token is paused
	isPaused, err := k.IsERC20TokenPaused(ctx, contractAddr)
	if err != nil {
		// Log the error but don't fail the transaction - EVM call failures shouldn't block transfers
		k.Logger(sdk.UnwrapSDKContext(ctx)).Error(
			"Failed to check ERC20 pause status",
			"contract", contractAddr,
			"error", err.Error(),
		)
		return nil
	}

	if isPaused {
		return errors.Wrapf(types.ErrRestrictedAction, "ERC20 token %s is paused", contractAddr)
	}

	// Check if sender is blacklisted
	if fromAddr != nil {
		isFromBlacklisted, err := k.IsERC20AddressBlacklisted(ctx, contractAddr, fromAddr)
		if err != nil {
			k.Logger(sdk.UnwrapSDKContext(ctx)).Error(
				"Failed to check sender blacklist status",
				"contract", contractAddr,
				"sender", fromAddr.String(),
				"error", err.Error(),
			)
			return nil
		}

		if isFromBlacklisted {
			return errors.Wrapf(types.ErrRestrictedAction, "sender %s is blacklisted for ERC20 token %s", fromAddr.String(), contractAddr)
		}
	}

	// Check if recipient is blacklisted
	if toAddr != nil {
		isToBlacklisted, err := k.IsERC20AddressBlacklisted(ctx, contractAddr, toAddr)
		if err != nil {
			k.Logger(sdk.UnwrapSDKContext(ctx)).Error(
				"Failed to check recipient blacklist status",
				"contract", contractAddr,
				"recipient", toAddr.String(),
				"error", err.Error(),
			)
			return nil
		}

		if isToBlacklisted {
			return errors.Wrapf(types.ErrRestrictedAction, "recipient %s is blacklisted for ERC20 token %s", toAddr.String(), contractAddr)
		}
	}

	return nil
}
