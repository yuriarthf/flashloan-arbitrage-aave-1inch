// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;


/**
 * @title Datatypes library
 * @author Yuri Fernandes
 * @notice Contains all complex data types required by the protocol
 */
library DataTypes {
  struct ExecuteOperationParams {
    // Asset to perform arbitrage
    address asset;
    // Amount of tokens
    uint256 amount;
    // Premium to be paid to Aave protocol
    uint256 premium;
    // Encoded params returned to executeOperation by Aave protocol
    bytes encodedPoolParams;
    // Fee to be paid
    uint16 fee;
    // Fee base
    uint16 feeBase;
  }
}