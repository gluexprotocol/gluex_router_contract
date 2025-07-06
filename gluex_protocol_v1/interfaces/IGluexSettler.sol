// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface of a GlueX Settler
interface IGluexSettler {
    
    /// @notice executes a structured settlement using the provided settlement parameters
    /// @param settlementParams The encoded parameters for the structured settlement
    /// @dev The settlement should be structured in a way that the contract can decode and use them to execute the settlement logic
    function executeStructuredSettlement(
        bytes calldata settlementParams
    ) external payable;

    /// @notice executes predefined settlement callback logic using parameters from data
    /// @param data The encoded data containing the necessary parameters for the settlement callback
    /// @dev The data should be encoded in a way that the contract can decode it to execute the settlement logic
    /// @dev This function should only be callable by GlueX's router contract in the implementation
    function executePreRouteCallback(
        bytes calldata data
    ) external payable;

    /// @notice executes predefined settlement callback logic using parameters from data
    /// @param data The encoded data containing the necessary parameters for the settlement callback
    /// @dev This function should only be callable by GlueX's router contract in the implementation
    function executePostRouteCallback(
        bytes calldata data
    ) external payable;
}