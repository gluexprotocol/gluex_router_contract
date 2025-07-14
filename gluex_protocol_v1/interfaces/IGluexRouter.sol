// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IExecutor} from "./IExecutor.sol";
import {Interaction, RouteDescription, CallbackData} from "../base/DataTypes.sol";

/// @title Interface of a GlueX Router
interface IGluexRouter {
    
    /**
     * @notice Executes a structured settlement using the provided callbacks, executor and interactions.
     * @param preRouteCallbackParams The parameters for the pre-route callback, including value and data.
     * @param executor The executor contract that performs the interactions.
     * @param desc The route description containing input, output, and fee details.
     * @param interactions The interactions encoded for execution by the executor.
     * @param postRouteCallbackParams The parameters for the post-route callback, including value and data.
     * @dev Ensures strict validation of slippage, routing fees, and input/output parameters.
    */
    function settle(
        CallbackData calldata preRouteCallbackParams,
        IExecutor executor,
        RouteDescription calldata desc,
        Interaction[] calldata interactions,
        CallbackData calldata postRouteCallbackParams
    ) external payable;
}