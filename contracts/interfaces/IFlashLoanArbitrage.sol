// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {IFlashLoanSimpleReceiver} from "./IFlashLoanSimpleReceiver.sol";
import {IAggregationExecutor} from "./ISwap.sol";

/**
 * @title IFlashLoanArbitrage
 * @author Yuri Fernandes
 * @notice Defines the interface for the FlashLoanArbitrage contract
 */
interface IFlashLoanArbitrage is IFlashLoanSimpleReceiver, IAggregationExecutor {
    /// @notice Emitted when arbitrage fees are claimed
    event ClaimedFee(address indexed to, address indexed asset, uint256 amount);

    /// @notice Emitted when tokens are rescued
    event TokensRescued(address indexed to, address indexed asset, uint256 amount);

    /// @notice Returns the base being used to calculate the fees, divides the protocol fees
    function FEE_BASE() external returns(uint16);

    /// @notice The size limit imposed to the path array
    function PATH_SIZE_LIMIT() external returns(uint8);

    /// @notice Returns the address of the DEX Aggregator being used for the swaps
    function DEX_AGGREGATOR() external returns(address);

    /// @notice Returns the protocol fees basis points
    function PROTOCOL_FEE_BPS() external returns(uint16);

    /**
     * @notice Returns the fees accrued for a determined asset
     * @return Fees accrued
     */
    function accruedFees(address asset) external returns(uint256);

    /**
     * @notice Withdraw fees for a determined asset
     * @dev Only the owner of the contract can execute this function
     * @param to Address to send the accrued fees
     * @param assets Addresses of the assets to withdraw the fees from
     */
    function withdrawFees(address to, address[] calldata assets) external;
    
    /**
     * @notice Rescue tokens accidentally sent to this contract
     * @dev Only the owner of the contract can execute this function
     * @param to Address to send the rescued tokens
     * @param asset Address of the asset to rescue tokens
     * @param amount Amount of tokens to rescue
     */
    function rescueTokens(address to, address asset, uint256 amount) external;

    /**
     * @notice Execute a flashloan, swap tokens using 1inch DEX aggregator, repays loan and claims profits
     * @dev The path array size is limited by the contract (currently 4) and should be at least 1
     * @param asset Address of the asset to perform the flashloan and arbitrage
     * @param amount The amount of tokens to ask from the flashloan
     * @param path The asset addresses to swap tokens before coming back to the borrowed asset
     * @param supplyToPool Whether to supply the profits to the Aave lending pool and receive aTokens, instead of the
     *      the underlying asset
     */
    function flashLoanArbitrage(address asset, uint256 amount, address[] calldata path, bool supplyToPool) external;
}