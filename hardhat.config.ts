import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

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

const accounts =
  process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [];

let etherscanApiKey: string | undefined;
if (process.env.POLYGON) {
  etherscanApiKey = process.env.POLYGONSCAN_API_KEY;
} else if (process.env.FANTOM != null) {
  etherscanApiKey = process.env.FTMSCAN_API_KEY;
} else if (process.env.ARBITRUM != null) {
  etherscanApiKey = process.env.ARBISCAN_API_KEY;
} else {
  etherscanApiKey = process.env.ETHERSCAN_API_KEY;
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    eth: { url: process.env.ETH_URL || "", accounts },
    polygon: { url: process.env.POLYGON_URL || "", accounts },
    fantom: { url: process.env.FANTOM_URL || "", accounts },
    xdai: { url: process.env.XDAI_URL || "", accounts },
    arbitrum: { url: process.env.ARBITRUM_URL || "", accounts },

    ropsten: { url: process.env.ROPSTEN_URL || "", accounts },
    rinkeby: { url: process.env.RINKEBY_URL || "", accounts },
    goerli: { url: process.env.GOERLI_URL || "", accounts },
    mumbai: { url: process.env.MUMBAI_URL || "", accounts },
    "arbitrum-rinkeby": {
      url: process.env.ARBITRUM_RINKEBY_URL || "",
      accounts,
    },
  },

  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },

  etherscan: { apiKey: etherscanApiKey },
};

export default config;
