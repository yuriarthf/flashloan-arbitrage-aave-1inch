// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IPoolAddressesProvider} from "./interfaces/IPoolAddressesProvider.sol";
import {IPool} from "./interfaces/IPool.sol";
import {ISwap, IAggregationExecutor} from "./interfaces/ISwap.sol";
import {IFlashLoanSimpleReceiver} from "./interfaces/IFlashLoanSimpleReceiver.sol";
import {IFlashLoanArbitrage} from "./interfaces/IFlashLoanArbitrage.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {DataTypes} from "./libraries/types/DataTypes.sol";
import {ArbitrageLogic} from "./libraries/logic/ArbitrageLogic.sol";
import {ValidationLogic} from "./libraries/logic/ValidationLogic.sol";


/**
 * @title FlashLoan Arbitrage Contract
 * @author Yuri Fernandes
 * @notice Make use of Aave flashloans and 1inch DEX aggregator to profit from arbitrage
 *      only capital for paying gas is required.
 */
contract FlashLoanArbitrage is IFlashLoanArbitrage, Ownable {

    /// @inheritdoc IFlashLoanArbitrage
    uint16 constant public override FEE_BASE = 1e4;

    /// @inheritdoc IFlashLoanArbitrage
    uint8 constant public override PATH_SIZE_LIMIT = 4;

    /// @inheritdoc IFlashLoanSimpleReceiver
    IPoolAddressesProvider immutable public override ADDRESSES_PROVIDER;
    /// @inheritdoc IFlashLoanArbitrage
    address immutable public override DEX_AGGREGATOR;
    /// @inheritdoc IFlashLoanArbitrage
    uint16 immutable public override PROTOCOL_FEE_BPS;

    /// @inheritdoc IFlashLoanArbitrage
    mapping(address => uint256) public override accruedFees;

    constructor(address poolAddressesProvider, address dexAggregator, uint16 protocolFee) Ownable(msg.sender) {
        ValidationLogic.validateFee(protocolFee, FEE_BASE);
        ValidationLogic.validateIsContract(poolAddressesProvider);
        ValidationLogic.validateIsContract(dexAggregator);
        ADDRESSES_PROVIDER = IPoolAddressesProvider(poolAddressesProvider);
        DEX_AGGREGATOR = dexAggregator;
        PROTOCOL_FEE_BPS = protocolFee;
    }

    /// @inheritdoc IFlashLoanArbitrage
    function withdrawFees(address to, address[] calldata assets) external override onlyOwner {
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 balance = accruedFees[assets[i]];
            if (balance == 0) continue;
            IERC20(assets[i]).transfer(to, balance);

            delete accruedFees[assets[i]];

            emit ClaimedFee(to, assets[i], balance);
        }
    }

    /// @inheritdoc IFlashLoanArbitrage
    function rescueTokens(address to, address asset, uint256 amount) external override onlyOwner {
        uint256 balance = IERC20(asset).balanceOf(address(this)) - accruedFees[asset];
        ValidationLogic.validateRescue(amount, balance);
        IERC20(asset).transfer(to, balance);

        emit TokensRescued(to, asset, amount);
    }

    /// @inheritdoc IAggregationExecutor
    function execute(address) external override payable {}

    /// @inheritdoc IFlashLoanSimpleReceiver
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address,
        bytes calldata params
    ) external override returns (bool) {
        return ArbitrageLogic.executeOperation(
            POOL(),
            DEX_AGGREGATOR,
            accruedFees,
            DataTypes.ExecuteOperationParams({
                asset: asset,
                amount: amount,
                premium: premium,
                encodedPoolParams: params,
                fee: PROTOCOL_FEE_BPS,
                feeBase: FEE_BASE
            })
        );
    }

    /// @inheritdoc IFlashLoanArbitrage
    function flashLoanArbitrage(address asset, uint256 amount, address[] calldata path, bool supplyToPool) external override {
        ArbitrageLogic.executeFlashLoanArbitrage(POOL(), path, PATH_SIZE_LIMIT, asset, amount, supplyToPool);
    }

    /// @inheritdoc IFlashLoanSimpleReceiver
    function POOL() public view override returns (IPool) {
        return IPool(ADDRESSES_PROVIDER.getPool());
    }
}