# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```javascript
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

# Reward Rates explained

The amount of tokens the user will receive depends on the amount of time they have staked their USDC, the reward rate for each duration, and the total amount of rewards available in the contract.

Assuming there are rewards available in the contract and the user has staked 100 USDC for the full duration, the user will receive the following amounts of tokens for each duration:

Duration 1: 100 USDC * 5 * 10^18 / (1 day * 365 days) = approximately 13.70 FarmCoin tokens
Duration 2: 100 USDC * 10 * 10^18 / (1 day * 365 days) = approximately 27.40 FarmCoin tokens
Duration 3: 100 USDC * 15 * 10^18 / (1 day * 365 days) = approximately 41.10 FarmCoin tokens
Duration 4: 100 USDC * 20 * 10^18 / (1 day * 365 days) = approximately 54.80 FarmCoin tokens

Note that these are approximate values and the actual amount of tokens the user receives may vary slightly due to changes in the reward rate and the total amount of rewards available in the contract.