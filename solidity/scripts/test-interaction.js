const { ethers } = require("hardhat");
const fs = require('fs');

async function main() {
  // Load deployment info
  const deploymentInfo = JSON.parse(fs.readFileSync('./deployment.json', 'utf8'));
  const contractAddress = deploymentInfo.contractAddress;
  
  const [deployer, alice, bob] = await ethers.getSigners();
  
  console.log("Testing MyUSDC contract at:", contractAddress);
  console.log("Deployer:", deployer.address);
  console.log("Alice:", alice.address);
  console.log("Bob:", bob.address);
  
  // Check deployment info to use correct contract type
  const contractType = deploymentInfo.contractType || "MyUSDC";
  console.log("Contract type:", contractType);
  
  // Get contract instance
  const MyUSDC = await ethers.getContractFactory(contractType);
  const myUSDC = MyUSDC.attach(contractAddress);
  
  console.log("\n=== Initial State ===");
  const initialPaused = await myUSDC.paused();
  console.log("Is paused:", initialPaused);
  console.log("Alice blacklisted:", await myUSDC.isBlacklisted(alice.address));
  console.log("Bob blacklisted:", await myUSDC.isBlacklisted(bob.address));
  
  // Check current balances
  const initialAliceBalance = await myUSDC.balanceOf(alice.address);
  const initialBobBalance = await myUSDC.balanceOf(bob.address);
  const totalSupply = await myUSDC.totalSupply();
  console.log("Alice current balance:", ethers.formatUnits(initialAliceBalance, 6), "mUSDC");
  console.log("Bob current balance:", ethers.formatUnits(initialBobBalance, 6), "mUSDC");
  console.log("Total supply:", ethers.formatUnits(totalSupply, 6), "mUSDC");
  
  // Reset contract to clean state for testing
  if (initialPaused) {
    console.log("\n🔧 Contract is paused, unpausing for test...");
    const unpauseTx = await myUSDC.unpause();
    await unpauseTx.wait();
    console.log("✅ Contract unpaused");
  }
  
  // Unblacklist addresses if needed
  const aliceBlacklisted = await myUSDC.isBlacklisted(alice.address);
  const bobBlacklisted = await myUSDC.isBlacklisted(bob.address);
  if (aliceBlacklisted) {
    console.log("🔧 Unblacklisting Alice...");
    const tx = await myUSDC.unblacklist(alice.address);
    await tx.wait();
    console.log("✅ Alice unblacklisted");
  }
  if (bobBlacklisted) {
    console.log("🔧 Unblacklisting Bob...");
    const tx = await myUSDC.unblacklist(bob.address);
    await tx.wait();
    console.log("✅ Bob unblacklisted");
  }
  
  console.log("\n=== Minting Tokens ===");
  const mintAmount = ethers.parseUnits("100", 6); // 100 mUSDC
  const mintTx = await myUSDC.mint(alice.address, mintAmount);
  await mintTx.wait();
  console.log("Minted 100 mUSDC to Alice");
  
  console.log("Alice balance:", ethers.formatUnits(await myUSDC.balanceOf(alice.address), 6));
  
  console.log("\n=== Testing Transfer ===");
  const transferAmount = ethers.parseUnits("10", 6); // 10 mUSDC
  const aliceContract = myUSDC.connect(alice);
  const transferTx = await aliceContract.transfer(bob.address, transferAmount);
  await transferTx.wait();
  console.log("Alice transferred 10 mUSDC to Bob");
  
  console.log("Alice balance:", ethers.formatUnits(await myUSDC.balanceOf(alice.address), 6));
  console.log("Bob balance:", ethers.formatUnits(await myUSDC.balanceOf(bob.address), 6));
  
  console.log("\n=== Testing Pause ===");
  const pauseTx = await myUSDC.pause();
  await pauseTx.wait();
  console.log("Token paused");
  
  try {
    await aliceContract.transfer(bob.address, transferAmount);
    console.log("ERROR: Transfer should have failed!");
  } catch (error) {
    console.log("✓ Transfer correctly failed while paused:", error.message);
  }
  
  const unpauseTx2 = await myUSDC.unpause();
  await unpauseTx2.wait();
  console.log("Token unpaused");
  
  console.log("\n=== Testing Blacklist ===");
  const blacklistTx = await myUSDC.blacklist(bob.address);
  await blacklistTx.wait();
  console.log("Bob blacklisted");
  
  try {
    await aliceContract.transfer(bob.address, transferAmount);
    console.log("ERROR: Transfer should have failed!");
  } catch (error) {
    console.log("✓ Transfer correctly failed to blacklisted address:", error.message);
  }
  
  const unblacklistTx = await myUSDC.unblacklist(bob.address);
  await unblacklistTx.wait();
  console.log("Bob unblacklisted");
  
  console.log("\n=== Final Test ===");
  const finalTransferTx = await aliceContract.transfer(bob.address, transferAmount);
  await finalTransferTx.wait();
  console.log("Transfer successful after unblacklisting");
  
  console.log("Alice final balance:", ethers.formatUnits(await myUSDC.balanceOf(alice.address), 6));
  console.log("Bob final balance:", ethers.formatUnits(await myUSDC.balanceOf(bob.address), 6));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
