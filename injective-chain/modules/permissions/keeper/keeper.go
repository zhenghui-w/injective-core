package keeper

import (
	"fmt"

	"cosmossdk.io/log"
	storetypes "cosmossdk.io/store/types"
	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/InjectiveLabs/injective-core/injective-chain/modules/permissions/types"
)

type Keeper struct {
	storeKey storetypes.StoreKey

	bankKeeper types.BankKeeper
	tfKeeper   types.TokenFactoryKeeper
	wasmKeeper types.WasmKeeper
	evmKeeper  types.EVMKeeper

	tfModuleAddress string
	moduleAccounts  map[string]bool
	authority       string
}

// NewKeeper returns a new instance of the x/permissions keeper
func NewKeeper(
	storeKey storetypes.StoreKey,
	bankKeeper types.BankKeeper,
	tfKeeper types.TokenFactoryKeeper,
	wasmKeeper types.WasmKeeper,
	evmKeeper types.EVMKeeper,
	tfModuleAddress string,
	moduleAccounts map[string]bool,
	authority string,
) Keeper {
	return Keeper{
		storeKey:        storeKey,
		bankKeeper:      bankKeeper,
		tfKeeper:        tfKeeper,
		wasmKeeper:      wasmKeeper,
		evmKeeper:       evmKeeper,
		tfModuleAddress: tfModuleAddress,
		moduleAccounts:  moduleAccounts,
		authority:       authority,
	}
}

// Logger returns a logger for the x/permissions module
func (k Keeper) Logger(ctx sdk.Context) log.Logger {
	return ctx.Logger().With("module", fmt.Sprintf("x/%s", types.ModuleName))
}
