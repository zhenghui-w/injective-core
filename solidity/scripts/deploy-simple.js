const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying MyUSDCSimple with the account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Bank precompile address on Injective
  const bankPrecompile = "0x0000000000000000000000000000000000000064";
  
  // Deploy MyUSDCSimple
  const MyUSDCSimple = await ethers.getContractFactory("MyUSDCSimple");
  const myUSDC = await MyUSDCSimple.deploy(bankPrecompile, deployer.address);
  
  await myUSDC.waitForDeployment();
  
  const contractAddress = await myUSDC.getAddress();
  console.log("MyUSDCSimple deployed to:", contractAddress);
  
  // Verify the contract is working
  console.log("Testing basic functions...");
  try {
    const name = await myUSDC.name();
    const symbol = await myUSDC.symbol();
    const decimals = await myUSDC.decimals();
    const owner = await myUSDC.owner();
    
    console.log("Name:", name);
    console.log("Symbol:", symbol);
    console.log("Decimals:", decimals);
    console.log("Owner:", owner);
    
    // Try to initialize metadata (this might fail, but that's ok)
    try {
      console.log("Attempting to initialize bank metadata...");
      const tx = await myUSDC.initializeMetadata();
      await tx.wait();
      console.log("✅ Bank metadata initialized successfully");
    } catch (error) {
      console.log("⚠️  Bank metadata initialization failed (expected if precompile not available)");
    }
    
  } catch (error) {
    console.error("Error testing contract:", error.message);
  }
  
  // Derive the ERC20 denom that will be used in the bank module
  const erc20Denom = `erc20:${contractAddress.toLowerCase()}`;
  console.log("ERC20 denom in bank module:", erc20Denom);
  
  // Save deployment info
  const deploymentInfo = {
    contractAddress,
    erc20Denom,
    bankPrecompile,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contractType: "MyUSDCSimple"
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
