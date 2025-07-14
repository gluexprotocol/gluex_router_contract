// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {AaveV3FlashLoaner} from "./utils/AaveV3FlashLoaner.sol";
import {GluexSettler} from "../../utils/GluexSettler.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {SafeERC20} from "../../lib/SafeERC20.sol"; 
import {Interaction, RouteDescription, CallbackData} from "../../base/DataTypes.sol";

contract GluexAaveV3FlashLiquidator is GluexSettler, AaveV3FlashLoaner {
    using SafeERC20 for IERC20;

    constructor(address _router, address _settlementTrigger) GluexSettler(_router, _settlementTrigger) {}

    function executeStructuredSettlement(
        bytes calldata settlementParams
    ) external payable override {

        // Decode the settlementParams to extract the necessary parameters for the flash loan
        (address debtToken, uint256 debtAmount, bytes memory params, uint16 referralCode) = 
            abi.decode(settlementParams, (address, uint256, bytes, uint16));
                
        // Ensure that the settlementParams are structured correctly to match the expected parameters for Aave's flashLoanSimple
        IPool(settlementTrigger).flashLoanSimple(address(this), debtToken, debtAmount, params, referralCode); 

        // TODO:
        // Add events to simplify GlueX integrators to track margins, types of settlements, and other relevant data
    }

    function executeOperation(
        IERC20 asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override onlySettlementTrigger returns (bool success) {

        require (initiator == address(this), "GlueX: unauthorized operation caller");

        (success, ) = gluexRouter.call{value: 0}(params);

        require(success, "GlueX: router call failed");
        
    }

    function executePreRouteCallback(
        bytes calldata data
    ) external payable override onlyGluexRouter{

        // Data must contain the parameters to execute pre-payment of liquidation and sourcing of collateral.
        (address debtReceiver, uint256 debtAmount, address collateralHolder, address collateralToken, uint256 collateralAmount) = abi.decode(data,(address, uint256, address, address, uint256));

        // Send liquidated debt sourced from flashloan to lender
        IERC20(collateralToken).safeTransferFromUniversal(
            address(this), 
            debtReceiver, 
            debtAmount,
            false
        );

        // Send collateral for routing to gluex router (prior approval from holder required)
        IERC20(collateralToken).safeTransferFromUniversal(
            collateralHolder,
            gluexRouter, 
            collateralAmount,
            false
        );
    }

    function executePostRouteCallback(
        bytes calldata data
    ) external payable override onlyGluexRouter {

        // Data must cotain parameters to execute approval to flashloan provider of flashloan + fee. 
        
        (address debtAsset, uint256 debtAmountWithPremium) = abi.decode(data, (address, uint256));

        IERC20(debtAsset).approve(settlementTrigger, debtAmountWithPremium);

        // TODO:
        // Add events to simplify GlueX integrators to track borrowed amounts and assets to render total positions to users

    }
}