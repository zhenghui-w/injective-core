#!/bin/bash

set -e

echo "🚀 Complete MyUSDC Integration Setup"
echo "===================================="

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Please run this script from the solidity/ directory"
    exit 1
fi

# Go back to project root
cd ..

echo "📍 Current directory: $(pwd)"

# Check for required tools
echo ""
echo "🔍 Checking prerequisites..."

if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go from https://golang.org/dl/"
    echo "   On macOS: brew install go"
    exit 1
else
    echo "✅ Go is installed: $(go version)"
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js from https://nodejs.org/"
    exit 1
else
    echo "✅ Node.js is installed: $(node --version)"
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq is not installed. Please install jq:"
    echo "   On macOS: brew install jq"
    echo "   On Ubuntu: sudo apt-get install jq"
    exit 1
else
    echo "✅ jq is installed"
fi

# Stop any running injectived process
echo ""
echo "🛑 Stopping any existing injectived processes..."
killall injectived &>/dev/null || true
sleep 2

# Clean up existing data
if [ -d ".injectived" ]; then
    echo "🧹 Removing existing .injectived directory..."
    rm -rf .injectived
fi

# Check if our EVM fix is in place
echo ""
echo "🔧 Checking EVM permissions fix..."
if grep -q "0x7cB61D4117AE31a12E393a1Cfa3BaC666481D02E" injective-chain/app/upgrades/v1.16.0/upgrade.go; then
    echo "✅ EVM permissions fix is already applied"
else
    echo "⚠️  EVM permissions fix is not applied. Contract deployment may fail."
    echo "   The fix has been documented in the README.md"
fi

# Run setup
echo ""
echo "🏗️  Running setup.sh to initialize the chain..."
if ./setup.sh > setup_output.log 2>&1; then
    echo "✅ Setup completed successfully"
else
    echo "❌ Setup failed. Check setup_output.log for details:"
    tail -10 setup_output.log
    exit 1
fi

# Start the node in background
echo ""
echo "🚀 Starting injectived node..."
nohup ./injectived.sh > node_output.log 2>&1 &
NODE_PID=$!

# Wait for node to start
echo "⏳ Waiting for node to start..."
for i in {1..30}; do
    if curl -s http://localhost:26657/status > /dev/null 2>&1; then
        echo "✅ Node is running (PID: $NODE_PID)"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Node failed to start. Check node_output.log for details:"
        tail -10 node_output.log
        exit 1
    fi
    sleep 2
done

# Wait for EVM JSON-RPC
echo "⏳ Waiting for EVM JSON-RPC to start..."
for i in {1..15}; do
    if curl -s http://localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' > /dev/null 2>&1; then
        echo "✅ EVM JSON-RPC is ready"
        break
    fi
    if [ $i -eq 15 ]; then
        echo "❌ EVM JSON-RPC failed to start"
        exit 1
    fi
    sleep 2
done

# Go to solidity directory and install dependencies
cd solidity

echo ""
echo "📦 Installing Node.js dependencies..."
if npm install > npm_install.log 2>&1; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies. Check npm_install.log for details"
    exit 1
fi

# Test deployment
echo ""
echo "🧪 Testing contract deployment..."
if npx hardhat run scripts/deploy-test.js --network injectiveLocal > deploy_test.log 2>&1; then
    echo "✅ Test contract deployed successfully!"
    CONTRACT_ADDR=$(grep "MyUSDCTest deployed to:" deploy_test.log | awk '{print $4}')
    echo "   Contract address: $CONTRACT_ADDR"
else
    echo "❌ Test deployment failed. Check deploy_test.log for details:"
    tail -5 deploy_test.log
fi

# Test basic interaction
echo ""
echo "🔄 Testing basic contract interaction..."
if npx hardhat run scripts/test-interaction.js --network injectiveLocal > interaction_test.log 2>&1; then
    echo "✅ Contract interaction test passed!"
else
    echo "⚠️  Contract interaction test failed. This may be due to EVM permissions."
    echo "   Check interaction_test.log for details:"
    tail -5 interaction_test.log
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "📋 Summary:"
echo "- ✅ Injective node running (PID: $NODE_PID)"
echo "- ✅ EVM JSON-RPC available at http://localhost:8545"
echo "- ✅ Cosmos RPC available at http://localhost:26657"
echo "- ✅ Node.js dependencies installed"
echo "- ✅ Test contract deployment attempted"
echo ""
echo "🔗 Next Steps:"
echo "1. Try deploying contracts: npm run deploy:local"
echo "2. Run EVM tests: npx hardhat run scripts/test-interaction.js --network injectiveLocal"
echo "3. Run full integration tests: ./scripts/test-cosmos-integration.sh"
echo ""
echo "📚 Documentation:"
echo "- Check README.md for detailed usage instructions"
echo "- Review solidity/fix-evm-permissions.md for permission issues"
echo ""
echo "🛑 To stop the node: kill $NODE_PID"
echo ""
echo "Happy coding! 🎯"
