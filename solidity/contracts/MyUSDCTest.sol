// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyUSDCTest
 * @dev Test version of controlled ERC20 token with pause and blacklist functionality
 * No bank precompile integration for testing purposes
 */
contract MyUSDCTest is ERC20, Ownable {
    mapping(address => bool) private _blacklist;
    bool private _paused;
    uint8 private _decimals;

    event Paused();
    event Unpaused();
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);

    modifier whenNotPaused() {
        require(!_paused, "MyUSDCTest: token transfer while paused");
        _;
    }

    modifier notBlacklisted(address account) {
        require(!_blacklist[account], "MyUSDCTest: account is blacklisted");
        _;
    }

    constructor(address initialOwner)
        ERC20("MyUSD Coin", "mUSDC")
        Ownable(initialOwner)
    {
        _decimals = 6;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // Pause controls
    function pause() external onlyOwner {
        _paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused();
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    // Blacklist controls
    function blacklist(address account) external onlyOwner {
        _blacklist[account] = true;
        emit Blacklisted(account);
    }

    function unblacklist(address account) external onlyOwner {
        _blacklist[account] = false;
        emit Unblacklisted(account);
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _blacklist[account];
    }

    // Mint function for testing
    function mint(address to, uint256 amount) public onlyOwner 
        whenNotPaused 
        notBlacklisted(to) 
    {
        _mint(to, amount);
    }

    function burn(uint256 amount) public 
        whenNotPaused 
        notBlacklisted(_msgSender()) 
    {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public 
        whenNotPaused 
        notBlacklisted(account) 
        notBlacklisted(_msgSender()) 
    {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function transfer(address to, uint256 amount) public override 
        whenNotPaused 
        notBlacklisted(_msgSender()) 
        notBlacklisted(to) 
        returns (bool) 
    {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override 
        whenNotPaused 
        notBlacklisted(_msgSender()) 
        notBlacklisted(from) 
        notBlacklisted(to) 
        returns (bool) 
    {
        return super.transferFrom(from, to, amount);
    }

    function approve(address spender, uint256 amount) public override 
        whenNotPaused 
        notBlacklisted(_msgSender()) 
        notBlacklisted(spender) 
        returns (bool) 
    {
        return super.approve(spender, amount);
    }
}

