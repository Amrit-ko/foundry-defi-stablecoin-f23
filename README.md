# Decentralized Stablecoin (DSC) Project

This repository contains the source code for the Decentralized Stablecoin (DSC) project, consisting of two main components: the DSCEngine smart contract and the DecentralizedStableCoin ERC20 token contract. Together, these contracts form the backbone of the Decentralized Stablecoin system.

## Overview

The Decentralized Stablecoin (DSC) project aims to create a stablecoin that maintains a 1 token == $1 peg at all times. The system is exogenously collateralized, dollar-pegged, and algorithmically stable. It allows users to deposit collateral, mint DSC, redeem collateral, and liquidate insolvent users' collateral.

## Contracts

### DSCEngine

The DSCEngine is the core smart contract of the Decentralized Stablecoin system. It handles all the logic for minting and redeeming DSC, as well as depositing and withdrawing collateral. Additionally, it monitors users' health factor to prevent insolvency.

### DecentralizedStableCoin

The DecentralizedStableCoin (DSC) contract is an ERC20 token designed to be owned by the DSCEngine smart contract. It serves as the stablecoin in the Decentralized Stablecoin system. The contract allows the owner to burn tokens and mint new tokens.

## Features

- Collateralization: Users can deposit collateral and mint DSC.
- Redemption: Users can redeem collateral by burning DSC.
- Liquidation: Allows liquidating insolvent users' collateral to cover their debt.
- Health Factor: Monitors users' health factor to prevent insolvency.
- ERC20 Compatibility: Implements the ERC20 standard for compatibility with Ethereum wallets and exchanges.
- Burn Functionality: Allows the contract owner to burn tokens.
- Mint Functionality: Enables the contract owner to mint new tokens.

## Smart Contract Layout

Both contracts follow a similar layout:

- Errors: Custom error messages for better clarity.
- State Variables: Storage variables and mappings.
- Events: Emitted events for external monitoring.
- Modifiers: Custom modifiers for input validation.
- Constructor: Initializes the contract with necessary parameters.
- External Functions: Publicly accessible functions.
- Public Functions: Functions available within the contract.
- Private Functions: Internal functions for contract logic.
- View & Pure Functions: Helper functions for data retrieval.

## Usage

### Deployment

Deploy both the DSCEngine and DecentralizedStableCoin contracts to the Ethereum network. Ensure proper initialization of contract parameters.

## Interaction

Interact with the contracts using provided external functions:

- Deposit Collateral: Call depositCollateral in DSCEngine to deposit collateral.
- Mint DSC: Use mint in DSCEngine to mint DSC against deposited collateral.
- Redeem Collateral: Redeem collateral by burning DSC with redeemCollateral in DSCEngine.
- Burn DSC: Burn DSC tokens to maintain health factor using the burnDsc function in DSCEngine.
- Burn Tokens: Call burn in DecentralizedStableCoin to burn a specific amount of tokens owned by the contract owner.
- Mint Tokens: Use mint in DecentralizedStableCoin to mint new tokens and assign them to a specified address.

## Prerequisites

Solidity 0.8.19

- OpenZeppelin Contracts library
- Chainlink Price Feed Aggregator (for DSCEngine)

## License

- This project is licensed under the MIT License.

## Disclaimer

This software is provided as-is with no warranties. Use at your own risk.
