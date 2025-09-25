require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    injectiveLocal: {
      url: "http://localhost:8545",
      accounts: [
        // Funded accounts from setup script
        "0xe9b1d63e8acd7fe676acb43afb390d4b0202dab61abec9cf2a561e4becb147de", // localkey (VAL_KEY)
        "0x88cbead91aee890d27bf06e003ade3d4e952427e88f88d31d61d3ef5e5d54305", // user1
        "0x741de4f8988ea941d3ff0287911ca4074e62b7d45c991a51186455366f10b544", // user2
        // Adding a known authorized deployer private key if available
        "0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e"  // placeholder - need to find actual key
      ],
      chainId: 1776
    }
  }
};