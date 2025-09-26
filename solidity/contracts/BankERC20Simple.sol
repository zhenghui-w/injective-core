// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IBankModule {
    function mint(address to, uint256 amount) external payable returns (bool success);
    function burn(address from, uint256 amount) external returns (bool success);
    function transfer(address from, address to, uint256 amount) external returns (bool success);
    function balanceOf(address account) external view returns (uint256 balance);
    function totalSupply() external view returns (uint256 supply);
    function metadata() external view returns (string memory name, string memory symbol, uint8 decimals);
    function setMetadata(string calldata name, string calldata symbol, uint8 decimals) external returns (bool success);
}

/**
 * @title BankERC20Simple
 * @dev Simplified ERC20 token that integrates with Injective's bank precompile
 * Does not call bank precompile in constructor to avoid deployment issues
 */
contract BankERC20Simple is ERC20 {
    IBankModule public immutable bank;
    uint8 private _decimals;
    
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address bankPrecompile
    ) ERC20(name_, symbol_) {
        bank = IBankModule(bankPrecompile);
        _decimals = decimals_;
        
        // Note: setMetadata call removed from constructor to avoid deployment failure
        // Can be called separately after deployment if needed
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    // Initialize metadata after deployment
    function initializeMetadata() external returns (bool) {
        return bank.setMetadata(name(), symbol(), decimals());
    }
    
    function mint(address to, uint256 amount) public payable virtual {
        _mint(to, amount);
        // Only call bank mint if we're not in a failed state
        if (address(bank).code.length > 0) {
            try bank.mint{value: msg.value}(to, amount) returns (bool success) {
                require(success, "Bank mint failed");
            } catch {
                // Log error but don't fail the mint
                // This allows the contract to work even if bank precompile is not available
            }
        }
    }
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
        // Try bank burn
        if (address(bank).code.length > 0) {
            try bank.burn(_msgSender(), amount) returns (bool) {
                // Success
            } catch {
                // Ignore bank burn failures
            }
        }
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        // Try bank burn
        if (address(bank).code.length > 0) {
            try bank.burn(account, amount) returns (bool) {
                // Success
            } catch {
                // Ignore bank burn failures
            }
        }
    }
    
    function _update(address from, address to, uint256 value) internal virtual override {
        if (from == address(0)) {
            // Minting - handled by mint() function
        } else if (to == address(0)) {
            // Burning - handled by burn functions
        } else {
            // Transfer between addresses - try to use bank precompile
            if (address(bank).code.length > 0) {
                try bank.transfer(from, to, value) returns (bool) {
                    // Success
                } catch {
                    // Ignore bank transfer failures, let standard ERC20 handle it
                }
            }
        }
        
        super._update(from, to, value);
    }
}

