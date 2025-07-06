// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {AaveV3FlashLoaner} from "./utils/AaveV3FlashLoaner.sol";
import {GluexSettler} from "./utils/GluexSettler.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IPool} from "./interfaces/IPool.sol";

contract GluexAaveV3FlashLoanSimple is GluexSettler, AaveV3FlashLoaner {

    constructor(address _router, address _settlementTrigger) GluexSettler(_router, _settlementTrigger) {}

    function executeStructuredSettlement(
        bytes calldata settlementParams
    ) external payable override {

        // Decode the settlementParams to extract the necessary parameters for the flash loan
        (address receiverAddress, address asset, uint256 amount, bytes memory params, uint16 referralCode) = 
            abi.decode(settlementParams, (address, address, uint256, bytes, uint16));

        // Ensure that the settlementParams are structured correctly to match the expected parameters for Aave's flashLoanSimple
        IPool(_settlementTrigger).flashLoanSimple(receiverAddress, asset, amount, params, referralCode); 

        // TODO:
        // Add events to simplify GlueX integrators to track margins, types of settlements, and other relevant data
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external onlySettlementTrigger returns (bool) {

        require (initiator == address(this), "GlueX: unauthorized operation caller");

        // Params in the context of GluexAaveV3FlashLoanSimple should only be the apprpriate calldata to
        // GlueX Protocol settle() function.

        (bool success, ) = gluexRouter.call{value: 0}(params);
        require(success, "GlueX: router call failed");
        
    }

    function executePostRouteCallback(
        bytes calldata data
    ) external payable override onlyGluexRouter {

        // Data must contain parameters to execute borrow of flashloan + fee. Tx.origin must have granted 
        // permission to the settlementTrigger contract to execute the borrow on its behalf.
        
        (address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode) = abi.decode(data, (address, uint256, uint256, uint16));
        IPool(_settlementTrigger).borrow(asset, amount, interestRateMode, referralCode, tx.origin);

        IERC20(asset).approve(_settlementTrigger, amount);

        // TODO:
        // Add events to simplify GlueX integrators to track borrowed amounts and assets to render total positions to users

    }
}