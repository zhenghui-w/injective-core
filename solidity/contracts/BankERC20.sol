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
 * @title BankERC20
 * @dev ERC20 token that integrates with Injective's bank precompile
 * Tokens minted via this contract are bridged to the Cosmos bank module
 */
contract BankERC20 is ERC20 {
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
        
        // Set metadata in the bank precompile
        bank.setMetadata(name_, symbol_, decimals_);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    function mint(address to, uint256 amount) public payable virtual {
        _mint(to, amount);
        // Mint in the bank module as well
        bank.mint{value: msg.value}(to, amount);
    }
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
        // Burn from the bank module as well
        bank.burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        // Burn from the bank module as well
        bank.burn(account, amount);
    }
    
    function _update(address from, address to, uint256 value) internal virtual override {
        if (from == address(0)) {
            // Minting - handled by mint() function
        } else if (to == address(0)) {
            // Burning - handled by burn functions
        } else {
            // Transfer between addresses - use bank precompile
            bank.transfer(from, to, value);
        }
        
        super._update(from, to, value);
    }
}
