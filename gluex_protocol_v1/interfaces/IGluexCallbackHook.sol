// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for making arbitrary calls
interface IGluexCallbackHook {

    /// @notice modifier to restrict access to functions to only GlueX's router contract
    modifier onlyGluexRouter() {
        // This modifier can be used to restrict access to functions to only GlueX's router contract.
        // The actual implementation of this modifier should check if msg.sender is the GlueX router address linked to this hook.
        _;
    }
    
    /// @notice executes a structured settlement using the provided hook parameters
    /// @param hookParams The encoded parameters for the structured settlement
    /// @dev The hookParams should be structured in a way that the contract can decode and use them to execute the settlement logic
    function executeStructuredSettlement(
        bytes calldata hookParams
    ) external payable;

    /// @notice executes predefined hook callback logic using parameters from data
    /// @param data The encoded data containing the necessary parameters for the hook callback
    /// @dev The data should be encoded in a way that the contract can decode it to execute the hook logic
    function executePreHookCallback(
        bytes calldata data
    ) external payable onlyGluexRouter;

    /// @notice executes predefined hook callback logic using parameters from data
    /// @param data The encoded data containing the necessary parameters for the hook callback
    function executePostHookCallback(
        bytes calldata data
    ) external payable onlyGluexRouter;
}
