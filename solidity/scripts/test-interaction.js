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
  console.log("Is paused:", await myUSDC.paused());
  console.log("Alice blacklisted:", await myUSDC.isBlacklisted(alice.address));
  console.log("Bob blacklisted:", await myUSDC.isBlacklisted(bob.address));
  
  console.log("\n=== Minting Tokens ===");
  const mintAmount = ethers.parseUnits("100", 6); // 100 mUSDC
  await myUSDC.mint(alice.address, mintAmount);
  console.log("Minted 100 mUSDC to Alice");
  
  console.log("Alice balance:", ethers.formatUnits(await myUSDC.balanceOf(alice.address), 6));
  
  console.log("\n=== Testing Transfer ===");
  const transferAmount = ethers.parseUnits("10", 6); // 10 mUSDC
  const aliceContract = myUSDC.connect(alice);
  await aliceContract.transfer(bob.address, transferAmount);
  console.log("Alice transferred 10 mUSDC to Bob");
  
  console.log("Alice balance:", ethers.formatUnits(await myUSDC.balanceOf(alice.address), 6));
  console.log("Bob balance:", ethers.formatUnits(await myUSDC.balanceOf(bob.address), 6));
  
  console.log("\n=== Testing Pause ===");
  await myUSDC.pause();
  console.log("Token paused");
  
  try {
    await aliceContract.transfer(bob.address, transferAmount);
    console.log("ERROR: Transfer should have failed!");
  } catch (error) {
    console.log("✓ Transfer correctly failed while paused:", error.message);
  }
  
  await myUSDC.unpause();
  console.log("Token unpaused");
  
  console.log("\n=== Testing Blacklist ===");
  await myUSDC.blacklist(bob.address);
  console.log("Bob blacklisted");
  
  try {
    await aliceContract.transfer(bob.address, transferAmount);
    console.log("ERROR: Transfer should have failed!");
  } catch (error) {
    console.log("✓ Transfer correctly failed to blacklisted address:", error.message);
  }
  
  await myUSDC.unblacklist(bob.address);
  console.log("Bob unblacklisted");
  
  console.log("\n=== Final Test ===");
  await aliceContract.transfer(bob.address, transferAmount);
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
