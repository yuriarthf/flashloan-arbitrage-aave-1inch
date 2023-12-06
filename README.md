# Flashloan Arbitrage (Avara Craft Challenge)

This project consists of a helper contract that allows anyone to perform atomic flashloans using Aave Protocol and perform arbitrage swaps using 1inch DEX aggregator (to find optimal prices across various DEXes) in exchange for a small fee over the arbitrage profit.

## Developed contracts
In order to build this project, some third party interfaces were used, the contracts that were entirely developed during the course of this project are:
1. [FlashLoanArbitrage.sol]("./contracts/FlashLoanArbitrage.sol"): Protocol contract to perform flashloan arbitrages;
2. [ArbitrageLogic.sol]("./contracts/libraries/logic/ArbitrageLogic.sol"): Contains the logic for the **FlaskLoanArbitrage** contract;
3. [ValidationLogic.sol]("./contracts/libraries/logic/ValidationLogic.sol"): Contains validations required by the to execute the protocol functions and errors;
4. [IFlashLoanArbitrage.sol]("./contracts/interfaces/IFlashLoanArbitrage.sol"): Contains the interface for the protocol;
5. [DataTypes.sol]("./contracts/libraries/types/DataTypes.sol): Store complex types required by the protocol.

## Setup
1. Create a `.env` file by running: `cp .env.example .env`;
2. Provide the following variables inside the newly created `.env` file:
   1. **ALCHEMY_KEY**: Alchemy RPC API key;
   2. **P_KEY**: Private key of the deployer;
   3. **AAVE_POOL_ADDRESSES_PROVIDER**: Aave PoolAddressesProvider address;
   4. **DEX_AGGREGATOR**: 1inch AggregationRouterV5 address;
   5. **PROTOCOL_FEE**: Protocol fee to charge for successful arbitrage operations in Basis points (0 <= **PROTOCOL_FEE** < 10000).
3. Compile contracts by running `yarn hardhat compile`;
4. Generate Typescript types for the contracts by running `yarn hardhat typechain`

## Deployment
In order to deploy the protocol, make sure that all environmental variables have been provided and run:    `yarn hardhat deploy --network <NETWORK_NAME>`.  
Current supported networks (`<NETWORK_NAME>`):
- sepolia (default);
- mainnet

## Tests
A possible approach to test the protocol, would be to fork ethereum's mainnet at a given block height and look for arbitrage opportunities.  
**TODO**
