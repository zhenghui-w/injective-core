# EVM Permissions Issue and Fix

## Problem
The Injective EVM is configured with `Permissioned = true`, which means only specific addresses in `AuthorizedDeployers` can deploy contracts. Our funded accounts are not in this list, causing contract deployment to succeed (transaction confirmed) but no contract code to be deployed.

## Current Authorized Deployers
```
"0x3fab184622dc19b6109349b94811493bf2a45362", // proxy 2 deployer
"0x05f32b3cc3888453ff71b01135b34ff8e41263f2", // multicall3 deployer
"0x40e6d40c9ecc1f503e89dfbb9de4f981ca1745dc", // WINJ9 deployer
"0xf1beb8f59c1b78080d70caf8549ac9319f525fa7", // deploy ERC20 MTS
```

## Our Accounts
- `0x7cB61D4117AE31a12E393a1Cfa3BaC666481D02E` (localkey from setup.sh)
- `0xC6Fe5D33615a1C52c08018c47E8Bc53646A0E101` (user1)
- `0x963EBDf2e1f8DB8707D05FC75bfeFFBa1B5BaC17` (user2)

## Solution 1: Modify Setup to Include Our Accounts
Add our account addresses to the authorized deployers list in the setup or configuration.

## Solution 2: Use Governance to Update Parameters
Use the governance module to update EVM parameters to include our addresses or disable permissioned deployment for testing.

## Solution 3: Find Private Keys for Authorized Deployers
Find the private keys for the existing authorized deployer addresses.

## Temporary Fix
For testing purposes, we need to either:
1. Restart the chain with modified parameters
2. Use a governance proposal to update the parameters
3. Find and use an existing authorized deployer account

## Files to Modify
- `injective-chain/app/upgrades/*/upgrade.go` - Where EVM params are set
- `setup.sh` - For localnet configuration
