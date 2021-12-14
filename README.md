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

## Deployment

Copy `.env.example` to `.env` and override the default values before deploying.

Deploy the contract:

```
yarn deploy --network ropsten
```

This will output the deployed contract address in the console.

### Verification

Verify on Etherscan, using the contract address from the previous step.

```
yarn verify --network ropsten $CONTRACT_ADDRESS
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
