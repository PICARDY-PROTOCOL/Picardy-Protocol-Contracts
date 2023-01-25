const { task } = require("hardhat/config");

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
//require("hardhat-contract-sizer");
require("@nomiclabs/hardhat-waffle");
//require("hardhat-gas-reporter");
require("solidity-docgen");
//require("@openzeppelin/hardhat-upgrades");

const dotenv = require("dotenv").config();
const privateKey = process.env.PRIVATE_KEY;
const urlEndpoint = process.env.HTTP_ENDPOINT;
const apiKey = process.env.POLYGONSCAN_API_KEY;

task("accounts", "Prints The List Of Accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    hardhat: {
      // See its defaults
    },
    polygonMumbai: {
      url: urlEndpoint,
      chainId: 80001,
      accounts: [privateKey],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },

      {
        version: "0.7.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
    ],
  },
  etherscan: {
    apiKey: {
      polygonMumbai: apiKey,
    },
    customChains: [
      {
        network: "polygonMumbai",
        chainId: 80001,
        urls: {
          apiURL: "https://api-testnet.polygonscan.com",
          browserURL: "https://mumbai.polygonscan.com",
        },
      },
    ],
  },

  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    only: [],
  },

  gasReporter: {
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
};
