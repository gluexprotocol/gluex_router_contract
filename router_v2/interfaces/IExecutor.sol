// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

/// @title Interface for making arbitrary calls
interface IExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function executeDynamicRoute(
        IERC20 inputToken,
        bytes calldata executionMap,
        IERC20 outputToken
    ) external payable;
}
