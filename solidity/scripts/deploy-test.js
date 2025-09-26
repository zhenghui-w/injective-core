const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying MyUSDCTest with the account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy MyUSDCTest (no bank precompile)
  const MyUSDCTest = await ethers.getContractFactory("MyUSDCTest");
  const myUSDC = await MyUSDCTest.deploy(deployer.address);
  
  await myUSDC.waitForDeployment();
  
  const contractAddress = await myUSDC.getAddress();
  console.log("MyUSDCTest deployed to:", contractAddress);
  
  // Verify the contract is working
  console.log("Testing basic functions...");
  try {
    const name = await myUSDC.name();
    const symbol = await myUSDC.symbol();
    const decimals = await myUSDC.decimals();
    const owner = await myUSDC.owner();
    const paused = await myUSDC.paused();
    
    console.log("✅ Name:", name);
    console.log("✅ Symbol:", symbol);
    console.log("✅ Decimals:", decimals);
    console.log("✅ Owner:", owner);
    console.log("✅ Paused:", paused);
    
  } catch (error) {
    console.error("❌ Error testing contract:", error.message);
  }
  
  // Derive the ERC20 denom that will be used in the bank module
  const erc20Denom = `erc20:${contractAddress.toLowerCase()}`;
  console.log("ERC20 denom in bank module:", erc20Denom);
  
  // Save deployment info
  const deploymentInfo = {
    contractAddress,
    erc20Denom,
    bankPrecompile: null, // No bank precompile for test version
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contractType: "MyUSDCTest"
  };
  
  const fs = require('fs');
  fs.writeFileSync(
    './deployment.json', 
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log("Deployment info saved to deployment.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

