require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
    solidity: "0.8.27", // Match your contract's Solidity version
    networks: {
        sepolia: {
            url: process.env.ALCHEMY_URL || "https://eth-sepolia.g.alchemy.com/v2/pN5R578E09YbnE8-nQ_ZGc0fY3FSsYqi",
            accounts: [process.env.PRIVATE_KEY],
        },
    },
};
