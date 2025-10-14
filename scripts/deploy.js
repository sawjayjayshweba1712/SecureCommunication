const hre = require ("hardhat");

async function main() {
    // Get the ContractFactory for AuthSystem
    const AuthManager = await hre.ethers.getContractFactory("AuthManager");
    
    // Deploy the contract
    const auth = await AuthManager.deploy();
    
    // Wait for deployment to complete (mining)
    await auth.deployed();

    console.log("Contract deployed to:", auth.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
