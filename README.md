# shell-contracts

Smart contracts for `shell`.

## Development

Install dependencies:

```
yarn
```

Compile all artifacts and generate typechain types:

```
yarn build
```

Run unit tests:

```
yarn test
```

Run unit tests showing gas usage by function and deploy costs:

```
REPORT_GAS=1 yarn test
```

Run unit tests and report coverage:

```
yarn test:coverage
```

If you have `shell-subgraph` and `shell-frontend` repos as sibling directories to this one, you can copy built ABIs to the appropriate location in those repos:

```
./copy-pasta-abis.sh
```

## Architecture

<p align="center">
  <img width="791" alt="Screen Shot 2021-12-15 at 12 12 52 AM" src="https://user-images.githubusercontent.com/644088/146133317-9031ef18-92e8-4876-b8dd-d5476bc90718.png">
</P>

* A `Factory` contract can deploy ERC-721 `Collection` contracts via OpenZeppelin's `Clone` util
* The collection owner can, at any time, install an **engine** that implements an `IEngine` interface ([strategy pattern](https://en.wikipedia.org/wiki/Strategy_pattern))
* The `tokenURI` and `getRoyaltyInfo` functions of the collection delegate to the currently installed engine
* The engine will be invoked before each NFT transfer/mint/burn (`beforeTokenTransfer`)
* The engine implements minting logic. Immutable data associated with the token can be written on mint by the engine
* The engine may store data (associated with either with the collection or a specific token) within the shell protocol. Stored data persists across engine hot-swaps
* Trustable data can be requested to be written to token storage on mint by the framework (such as minter, block height, etc).
* Engines and NFT owners cannot modify framework data
* Token owners may write any data they wish to tokens. Engines cannot modify this data

## Deployment

Copy `.env.example` to `.env` and override the default values before deploying.

Deploy the contract:

```
yarn deploy --network rinkeby
```

This will output the deployed contract address in the console.

### Verification

Verify on Etherscan, using the contract address from the previous step.

```
yarn verify --network rinkeby $CONTRACT_ADDRESS
```

Verification may fail if run too quickly after contract deployment.

If you are verifying for `polygon` or `mumbai` networks, set the `POLYGON` env var:

```
POLYGON=1 yarn verify --network polygon $CONTRACT_ADDRESS
```

If you are verifying for the `arbitrum` or `arbitrum-rinkeby` network, set the `ARBITRUM` env var:

```
ARBITRUM=1 yarn verify --network arbitrum $CONTRACT_ADDRESS
```

If you are verifying for the `fantom` network, set the `FANTOM` env var:

```
FANTOM=1 yarn verify --network fantom $CONTRACT_ADDRESS
```

### Test Fixtures

To deploy test fixtures and contracts (can help with testing):

```
yarn deploy:fixtures --network rinkeby
```
