// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BankERC20.sol";

/**
 * @title MyUSDC
 * @dev A controlled ERC20 token with pause and blacklist functionality
 * Integrates with Injective's bank precompile for cross-module compatibility
 */
contract MyUSDC is BankERC20, Ownable {
    mapping(address => bool) private _blacklist;
    bool private _paused;

    event Paused();
    event Unpaused();
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);

    modifier whenNotPaused() {
        require(!_paused, "MyUSDC: token transfer while paused");
        _;
    }

    modifier notBlacklisted(address account) {
        require(!_blacklist[account], "MyUSDC: account is blacklisted");
        _;
    }

    constructor(address bankPrecompile, address initialOwner)
        BankERC20("MyUSD Coin", "mUSDC", 6, bankPrecompile)
        Ownable(initialOwner)
    {}

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

    // Override functions to add pause and blacklist checks
    function mint(address to, uint256 amount) public payable override 
        whenNotPaused 
        notBlacklisted(to) 
        onlyOwner 
    {
        super.mint(to, amount);
    }

    function burn(uint256 amount) public override 
        whenNotPaused 
        notBlacklisted(_msgSender()) 
    {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override 
        whenNotPaused 
        notBlacklisted(account) 
        notBlacklisted(_msgSender()) 
    {
        super.burnFrom(account, amount);
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
