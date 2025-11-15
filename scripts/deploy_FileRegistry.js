const { ethers } = require("hardhat");

// ⚠️ STEP 1: Replace this with the ACTUAL deployed address of your AuthManager.sol
const AUTH_MANAGER_ADDRESS = "0xF25AB40f6648CeeDcf1166aC19634DcBBE2B0ac1"; 

async function main() {
  console.log("Starting FileRegistry deployment...");

  // 1. Get the Contract Factory
  const FileRegistry = await ethers.getContractFactory("FileRegistry");

  // 2. Deploy the contract, passing the AuthManager address to the constructor
  const fileRegistry = await FileRegistry.deploy(AUTH_MANAGER_ADDRESS);

  // 3. Wait for the deployment to finish
  await fileRegistry.deployed();

  console.log("------------------------------------------");
  console.log(`✅ FileRegistry deployed to: ${fileRegistry.address}`);
  console.log(`AuthManager dependency set to: ${AUTH_MANAGER_ADDRESS}`);
  console.log("------------------------------------------");

  // 4. IMPORTANT: Update the FILE_CONTRACT_ADDRESS in files.html with this new address!
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });