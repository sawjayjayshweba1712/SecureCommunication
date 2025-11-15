const { ethers } = require("hardhat");

// ⚠️ STEP 1: Replace this with the ACTUAL deployed address of your AuthManager.sol
// Based on your provided files, the AuthManager address is:
const AUTH_MANAGER_ADDRESS = "0xE71c11CF485D9ac41f051b20018CF2d2bD1d2ABe"; 

async function main() {
  console.log("Starting SubmissionManager deployment...");

  // 1. Get the Contract Factory.
  // Ensure "SubmissionManager" matches the contract name in SubmissionManager.sol
  const SubmissionManager = await ethers.getContractFactory("SubmissionManager");

  console.log(`Deploying SubmissionManager with AuthManager address: ${AUTH_MANAGER_ADDRESS}`);
  
  // 2. Deploy the contract. The constructor requires the AuthManager address.
  const submissionManager = await SubmissionManager.deploy(AUTH_MANAGER_ADDRESS);

  // 3. Wait for the deployment transaction to be mined (finished)
  await submissionManager.deployed();

  console.log("------------------------------------------");
  console.log(`✅ SubmissionManager deployed to: ${submissionManager.address}`);
  console.log(`AuthManager dependency set to: ${AUTH_MANAGER_ADDRESS}`);
  console.log("------------------------------------------");

  // 4. IMPORTANT: Copy the new address above and paste it into the 
  // SUBMISSION_MANAGER_ADDRESS variable in your 'files.html' page.
}

// Execute the deployment script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });