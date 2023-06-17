require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@tableland/hardhat");
require("dotenv").config();
/** @type import('hardhat/config').HardhatUserConfig */
ALCHEMY_PRIVATE_KEY = process.env.ALCHEMY_PRIVATE_KEY;
WALLET_PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY;
module.exports = {
  solidity: "0.8.18",
  localTableland: {
    silent: false,
    verbose: false,
  },
  networks: {
    hardhat: {},
    polygon_mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_PRIVATE_KEY}`,
      accounts: [WALLET_PRIVATE_KEY],
    },
  },
};
