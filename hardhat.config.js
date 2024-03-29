require("@nomiclabs/hardhat-ethers")
require("hardhat-gas-reporter")
require("@nomiclabs/hardhat-etherscan")
require("dotenv").config()
require("solidity-coverage")


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY 
const ARBI_GOERLI_RPC_URL = process.env.ARBI_GOERLI_RPC_URL
const PRIVATE_KEY =process.env.PRIVATE_KEY 
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY 
const ARBI_API_KEY = process.env.ARBI_API_KEY

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            // gasPrice: 130000000000,
        },
        arbigoerli: {
            url: ARBI_GOERLI_RPC_URL,
            accounts: [PRIVATE_KEY],
            chainId: 421613,
            blockConfirmations: 6,
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.8.4",
                settings: {},
            },
        ],
    },
    etherscan: {
        apiKey: ARBI_API_KEY,
        // customChains: [], // uncomment this line if you are getting a TypeError: customChains is not iterable

    },
    gasReporter: {
        enabled: true,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        // coinmarketcap: COINMARKETCAP_API_KEY,
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
    },
    mocha: {
        timeout: 500000,
    },
}
