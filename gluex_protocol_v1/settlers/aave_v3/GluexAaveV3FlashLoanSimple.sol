// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {AaveV3FlashLoaner} from "./utils/AaveV3FlashLoaner.sol";
import {GluexSettler} from "../../utils/GluexSettler.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {SafeERC20} from "../../lib/SafeERC20.sol"; 
import {Interaction, RouteDescription, CallbackData} from "../../base/DataTypes.sol";

contract GluexAaveV3FlashLoanSimple is GluexSettler, AaveV3FlashLoaner {
    using SafeERC20 for IERC20;

    constructor(address _router, address _settlementTrigger) GluexSettler(_router, _settlementTrigger) {}

    function skipSelector(bytes memory input) internal pure returns (bytes memory result) {
        require(input.length > 4, "GlueX: invalid calldata length");

        assembly {
            // Get the length after skipping selector (input.length - 4)
            let len := sub(mload(input), 4)

            // Allocate new memory for the sliced bytes
            result := mload(0x40)
            mstore(result, len)

            // Copy the bytes after the 4-byte selector
            let src := add(add(input, 0x20), 4)     // skip selector
            let dest := add(result, 0x20)
            for { let i := 0 } lt(i, len) { i := add(i, 0x20) } {
                mstore(add(dest, i), mload(add(src, i)))
            }

            // Update free memory pointer
            mstore(0x40, add(dest, len))
        }
    }

    function executeStructuredSettlement(
        bytes calldata settlementParams
    ) external payable override {

        // Decode the settlementParams to extract the necessary parameters for the flash loan
        (address receiverAddress, address asset, uint256 amount, bytes memory params, uint16 referralCode) = 
            abi.decode(settlementParams, (address, address, uint256, bytes, uint16));
        
        bytes memory stripped = skipSelector(params);

        (, , RouteDescription memory desc, , ) = abi.decode(stripped, (CallbackData, address, RouteDescription, Interaction[], CallbackData));

        // Ensure margin amount lands on GlueX Router prior to flashloan flow
        desc.inputToken.safeTransferFromUniversal(
            msg.sender, 
            gluexRouter, 
            desc.marginAmount,
            desc.isPermit2
        );

        // Ensure that the settlementParams are structured correctly to match the expected parameters for Aave's flashLoanSimple
        IPool(settlementTrigger).flashLoanSimple(receiverAddress, asset, amount, params, referralCode); 

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

        // By construction, Aave v3 Pool sends funds and triggers callback on settler
        asset.safeTransfer(gluexRouter, amount);

        // Params in the context of GluexAaveV3FlashLoanSimple should only be the apprpriate calldata to
        // GlueX Protocol settle() function.

        (success, ) = gluexRouter.call{value: 0}(params);
        require(success, "GlueX: router call failed");
        
    }

    function executePreRouteCallback(
        bytes calldata data
    ) external payable override onlyGluexRouter{
        // Default: no-op
    }

    function executePostRouteCallback(
        bytes calldata data
    ) external payable override onlyGluexRouter {

        // Data must contain parameters to execute borrow of flashloan + fee. Tx.origin must have granted 
        // permission to the settlementTrigger contract to execute the borrow on its behalf.
        
        (address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode) = abi.decode(data, (address, uint256, uint256, uint16));
        IPool(settlementTrigger).borrow(asset, amount, interestRateMode, referralCode, msg.sender);

        IERC20(asset).approve(settlementTrigger, amount);

        // TODO:
        // Add events to simplify GlueX integrators to track borrowed amounts and assets to render total positions to users

    }
}