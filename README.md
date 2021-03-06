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

## Deployment

Copy `.env.example` to `.env` and override the default values before deploying.

Deploy a contract (eg, ShellFactory):

```
yarn deploy --network rinkeby --contract ShellFactory
```

This will output the deployed contract address in the console and update the `./tasks/deployments.json` file.

> NOTE: The contract will automatically be verified on etherscan

### Deploying Implementations

To deploy a token model / implementation and register it with the corresponding shell factory:

```
yarn deploy:implementation --network rinkeby --contract ShellERC721 --implementation erc721-v1
```

This will deploy and verify the contract, as well as call the register method on the factory. This won't work if factory ownership has been transferred to a non-dev wallet.

To register an existing deployment:

```
yarn register --network rinkeby --address 0x123..123 --implementation erc721-prototype
```

### Verification

The `deploy` task will automatically verify contracts generally.

This can occasionally fail. If it does, verify manually:

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

## Publishing

This repo is published to npm so it can be installed as a dependency to downstream smart contract repos (such as engines).

Create a new version:

```
npm version 1.1.0
```

Make sure build artifacts are recent:

```
yarn clean && yarn build
```

Publish:

```
npm publish
```



