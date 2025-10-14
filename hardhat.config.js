require("@nomiclabs/hardhat-ethers");
require("dotenv").config(); // Load environment variables

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
    },
    // Retain localhost for testing
    localhost: {
      url: "http://127.0.0.1:8545",
    },
  },
};