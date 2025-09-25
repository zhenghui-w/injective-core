# MyUSDC Integration with Injective

This directory contains a complete implementation of MyUSDC, a controlled ERC20 token that integrates with Injective's Cosmos bank module to enforce pause and blacklist restrictions across all transfers, including IBC.

## Architecture

### 1. EVM Side (Solidity)

- **MyUSDC.sol**: Main ERC20 contract with pause and blacklist functionality
- **BankERC20.sol**: Base contract that integrates with Injective's bank precompile
- Uses OpenZeppelin's Ownable for access control

### 2. Cosmos Side (Go)

- **permissions/keeper/evm_hooks.go**: EVM contract interaction methods
- **permissions/keeper/send_restriction.go**: Modified to check ERC20 contract state
- **app.go**: Wired with EVM keeper dependency

### 3. Integration Flow

1. **EVM Contract State**: MyUSDC contract maintains pause status and blacklist mapping
2. **Bank Send Hook**: Every bank send operation checks the ERC20 contract's state
3. **Static Calls**: Uses EVM keeper to call `paused()` and `isBlacklisted(address)` methods
4. **Restriction Enforcement**: Blocks transfers if token is paused or addresses are blacklisted

## Deployment & Testing

### Prerequisites

1. **Start Localnet**:
   ```bash
   cd ../..
   ./setup.sh
   ./injectived.sh
   ```

2. **Install Dependencies**:
   ```bash
   npm install
   ```

### Deploy Contract

```bash
npm run deploy:local
```

This creates a `deployment.json` file with contract address and ERC20 denom.

### Run Tests

#### EVM-only Tests
```bash
npx hardhat run scripts/test-interaction.js --network injectiveLocal
```

#### Full Cosmos Integration Tests
```bash
./scripts/test-cosmos-integration.sh
```

## Usage Examples

### 1. Deploy and Mint

```javascript
const MyUSDC = await ethers.getContractFactory("MyUSDC");
const bankPrecompile = "0x0000000000000000000000000000000000000064";
const myUSDC = await MyUSDC.deploy(bankPrecompile, deployer.address);

// Mint tokens
await myUSDC.mint(userAddress, ethers.parseUnits("100", 6));
```

### 2. Pause Token

```javascript
await myUSDC.pause();
// Now all Cosmos bank sends will fail for this token
```

### 3. Blacklist Address

```javascript
await myUSDC.blacklist(userEthAddress);
// Now this address cannot send or receive via Cosmos
```

### 4. Cosmos Bank Transfer

```bash
# This will be blocked if token is paused or addresses are blacklisted
injectived tx bank send alice bob 1000000erc20:0x... \
  --from alice --chain-id injective-1
```

## Key Features

- ✅ **EVM-Cosmos Bridge**: Tokens minted via EVM are available in Cosmos bank module
- ✅ **Pause Control**: EVM contract pause state blocks all Cosmos transfers
- ✅ **Blacklist Enforcement**: EVM blacklist prevents restricted addresses from transferring
- ✅ **IBC Compatible**: Restrictions apply to IBC transfers automatically
- ✅ **Gas Efficient**: Uses static calls to minimize gas consumption
- ✅ **Error Handling**: Graceful degradation if EVM calls fail

## Contract Addresses

- **Bank Precompile**: `0x0000000000000000000000000000000000000064`
- **MyUSDC Contract**: See `deployment.json` after deployment

## Token Denomination

ERC20 tokens bridged to Cosmos use the format: `erc20:0xcontractaddress`

Example: `erc20:0x5fbdb2315678afecb367f032d93f642f64180aa3`

## Security Considerations

1. **Owner Control**: Only the contract owner can pause/unpause and manage blacklists
2. **Fail-Safe**: EVM call failures won't block transfers (logged as warnings)
3. **Gas Limits**: Conservative gas caps prevent DoS attacks
4. **Address Conversion**: Proper conversion between Cosmos and Ethereum address formats

## Integration Points

This implementation demonstrates how to:

1. **Extend Permissions Module**: Add EVM keeper dependency
2. **Hook Bank Sends**: Intercept all bank send operations
3. **Static EVM Calls**: Query contract state from Cosmos modules
4. **Error Handling**: Graceful degradation and logging
5. **Cross-Chain State**: Use EVM contract state to control Cosmos operations
