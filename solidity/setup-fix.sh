#!/bin/bash

# Fix for EVM Permissions Issue
# This script updates the setup to allow contract deployment from our funded accounts

echo "🔧 Fixing EVM Permissions for MyUSDC Testing"
echo "============================================="

# Kill existing injectived process
echo "Stopping existing injectived process..."
killall injectived &>/dev/null || true
sleep 2

# Remove existing data directory to ensure clean restart
if [ -d ".injectived" ]; then
    echo "Removing existing .injectived directory..."
    rm -rf .injectived
fi

# Run setup script to recreate the chain
echo "Running setup.sh to recreate the chain with updated parameters..."
./setup.sh

echo ""
echo "✅ Setup complete! The chain has been restarted with updated EVM parameters."
echo "Your funded accounts are now authorized to deploy contracts:"
echo "- 0x7cB61D4117AE31a12E393a1Cfa3BaC666481D02E (localkey)"
echo "- 0xC6Fe5D33615a1C52c08018c47E8Bc53646A0E101 (user1)"  
echo "- 0x963EBDf2e1f8DB8707D05FC75bfeFFBa1B5BaC17 (user2)"
echo ""
echo "You can now:"
echo "1. cd solidity"
echo "2. npm run deploy:local"
echo "3. npm run test"
echo ""
echo "Start the node with: ./injectived.sh"
