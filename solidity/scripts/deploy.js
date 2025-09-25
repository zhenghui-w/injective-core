const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Bank precompile address on Injective
  const bankPrecompile = "0x0000000000000000000000000000000000000064";
  
  // Deploy MyUSDC
  const MyUSDC = await ethers.getContractFactory("MyUSDC");
  const myUSDC = await MyUSDC.deploy(bankPrecompile, deployer.address);
  
  await myUSDC.waitForDeployment();
  
  const contractAddress = await myUSDC.getAddress();
  console.log("MyUSDC deployed to:", contractAddress);
  
  // Derive the ERC20 denom that will be used in the bank module
  const erc20Denom = `erc20:${contractAddress.toLowerCase()}`;
  console.log("ERC20 denom in bank module:", erc20Denom);
  
  // Save deployment info
  const deploymentInfo = {
    contractAddress,
    erc20Denom,
    bankPrecompile,
    deployer: deployer.address,
    timestamp: new Date().toISOString()
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
