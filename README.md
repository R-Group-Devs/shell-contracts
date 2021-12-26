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
