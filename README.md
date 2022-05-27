# NFT Staking project
With help of this project you can create an NFT project, which you can stake and get ERC-20 (Coin) as reward.

This project made using [Hardhat](https://hardhat.org/).

To deploy the contracts use the following commands:
```shell
npm install
npx hardhat compile
npx hardhat run scripts/deploy.js
```
## Deploying to remote networks
To deploy to a remote network such as mainnet or any testnet, you need to add a network entry to your `hardhat.config.js` file.

We’ll use [Oasis Emerald Network](https://docs.oasis.dev/general/developer-resources/emerald-paratime/) for this example, but you can add any network similarly:
```javascript
module.exports = {
  solidity: "0.8.4",
  networks: {
    emeraldTestnet: {
      url: 'https://testnet.emerald.oasis.dev',
      accounts: [
        `${ROPSTEN_PRIVATE_KEY}`,
      ],
    }
  }
};
```
Finally, run:
```shell
npx hardhat run scripts/deploy.js --network emeraldTestnet
```
## Running Tests
To test the smart contracts run:
```shell
npx hardhat test test/sample-test.js
```
