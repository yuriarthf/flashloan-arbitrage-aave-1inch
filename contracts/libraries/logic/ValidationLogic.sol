// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {IPool} from "../../interfaces/IPool.sol";

// Thrown when address is not a contract
error NotContract(address addr);
// Thrown when the the chosen fee is not a valid basis point
error InvalidFee();
// Thrown when the caller is not the pool
error OnlyPool();
// Thrown when the amount of assets to be rescued exceeds the total lost amount
error NoRescue();
// Thrown when the chosen path size is not valid (zero and above the maximum size)
error InvalidPath();
// Thrown when provided address is the zero address
error ZeroAddress();

/**
 * @title Validation Logic Library
 * @author Yuri Fernandes
 * @notice Implements validation logic
 * @dev Library is set to be an internal library, since underlying contract is small
 */
library ValidationLogic {
    function validateFee(uint16 fee, uint16 feeBase) internal pure {
        if (fee > feeBase) revert InvalidFee(); 
    }

    function validateIsContract(address addr) internal view {
        if (addr.code.length == 0) revert NotContract(addr);
    }

    function validateNotZeroAddress(address addr) internal pure {
        if (addr == address(0)) revert ZeroAddress();
    }

    function validateRescue(uint256 amountToRescue, uint256 assetBalance) internal pure {
        if (assetBalance < amountToRescue) revert NoRescue();
    }

    function validatePath(address[] calldata path, uint256 maximumSize) internal pure {
        if (path.length == 0 || path.length > maximumSize) revert InvalidPath();
    }

    function validatePool(IPool pool) internal view {
        if (address(pool) != msg.sender) revert OnlyPool();
    }
}