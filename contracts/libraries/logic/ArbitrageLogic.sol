// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IFlashLoanSimpleReceiver} from "../../interfaces/IFlashLoanSimpleReceiver.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {ISwap, IAggregationExecutor} from "../../interfaces/ISwap.sol";

import {DataTypes} from "../types/DataTypes.sol";
import {ValidationLogic} from "./ValidationLogic.sol";

/**
 * @title Arbitrage Logic Library
 * @author Yuri Fernandes
 * @dev Implements flashloan arbitrage logic
 * @dev Library is set to be an internal library, since underlying contract is small
 */
library ArbitrageLogic {

    event Profits(address indexed caller, address indexed asset, uint256 profit, bool supplyToPool);

    function executeFlashLoanArbitrage(
        IPool pool, address[]
        calldata path,
        uint256 pathMaximumSize,
        address asset,
        uint256 amount,
        bool supplyToPool
    ) internal {
        // path has limited size
        ValidationLogic.validatePath(path, pathMaximumSize);

        // for now just tokens are supported, but WETH logic could be
        // added if zero address is provided
        ValidationLogic.validateNotZeroAddress(asset);

        // Perform flash loan
        pool.flashLoanSimple(
            address(this),
            asset,
            amount,
            abi.encode(msg.sender, supplyToPool, path),
            0
        );
    }

    function executeOperation(
        IPool pool,
        address dexAggregator,
        mapping(address => uint256) storage accruedFees,
        DataTypes.ExecuteOperationParams memory params
    ) internal returns (bool) {
        // check if sender is the pool
        ValidationLogic.validatePool(pool);

        // decode params
        (address caller, bool supplyToPool, address[] memory interAssets) = abi.decode(
            params.encodedPoolParams,
            (address, bool, address[])
        );

        uint256 returnAmount = _approveAndSwapUsingAggregator(dexAggregator, params.asset, interAssets[0], params.amount);
        for (uint256 i = 1; i < interAssets.length; i++) {
            returnAmount = _approveAndSwapUsingAggregator(dexAggregator, interAssets[i-1], interAssets[i], returnAmount);
        }
        returnAmount = _approveAndSwapUsingAggregator(dexAggregator, interAssets[interAssets.length-1], params.asset, returnAmount);

        uint256 repay = params.amount + params.premium;
        if (returnAmount < repay) {
            return false;
        }

        IERC20(params.asset).approve(msg.sender, repay);

        uint256 profit = (returnAmount - repay) * (params.feeBase - params.fee) / params.feeBase;
        accruedFees[params.asset] += returnAmount - repay - profit;

        if (supplyToPool) {
            IERC20(params.asset).approve(address(pool), profit);
            IPool(pool).supply(
                params.asset,
                profit,
                caller,
                0
            );
        } else {
            IERC20(params.asset).transfer(caller, profit);
        }

        emit Profits(caller, params.asset, profit, supplyToPool);

        return true;
    }

    function _approveAndSwapUsingAggregator(
        address dexAggregator,
        address fromAsset,
        address toAsset,
        uint256 amount
    ) private returns (uint256) {
        IERC20(fromAsset).approve(dexAggregator, amount);
        (uint256 returnAmount,) = ISwap(dexAggregator).swap(
            IAggregationExecutor(address(this)),
            ISwap.SwapDescription({
                srcToken: IERC20(fromAsset),
                dstToken: IERC20(toAsset),
                srcReceiver: payable(address(this)),
                dstReceiver: payable(address(this)),
                amount: amount,
                minReturnAmount: 0,
                flags: 0
            }),
            ""
        );
        return returnAmount;
    }
}