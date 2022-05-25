require("@nomiclabs/hardhat-waffle");
require("hardhat-abi-exporter");
require("hardhat-gas-reporter");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  abiExporter: [
    {
      path: "./contracts/abi/pretty",
      clear: true,
      flat: true,
      only: ["NFT", "StakeSystem", "Coin"],
      pretty: true,
      spacing: 2,
    },
    {
      path: "./contracts/abi/ugly",
      clear: true,
      flat: true,
      only: ["NFT", "StakeSystem", "Coin"],
      pretty: false,
      spacing: 2,
    },
  ],
  gasReporter: {
    enabled: true,
    coinmarketcap: "326e1108-51d4-474a-8859-790e20dc7936",
    currency: "ETH",
    token: "ETH",
    gasPriceApi:
        "https://api.etherscan.io/api?module=proxy&action=eth_gasPrice",
  },
};
