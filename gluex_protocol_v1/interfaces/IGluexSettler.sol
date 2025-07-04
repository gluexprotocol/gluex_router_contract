// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface of a GlueX Settler
interface IGluexSettler {

    /// @notice modifier to restrict access to functions to only GlueX's router contract
    modifier onlyGluexRouter() {
        // This modifier can be used to restrict access to functions to only GlueX's router contract.
        // The actual implementation of this modifier should check if msg.sender is the GlueX router address linked to this settlement.
        _;
    }
    
    /// @notice executes a structured settlement using the provided settlement parameters
    /// @param settlementParams The encoded parameters for the structured settlement
    /// @dev The settlement should be structured in a way that the contract can decode and use them to execute the settlement logic
    function executeStructuredSettlement(
        bytes calldata settlementParams
    ) external payable;

    /// @notice executes predefined settlement callback logic using parameters from data
    /// @param data The encoded data containing the necessary parameters for the settlement callback
    /// @dev The data should be encoded in a way that the contract can decode it to execute the settlement logic
    function executePreRouteCallback(
        bytes calldata data
    ) external payable onlyGluexRouter;

    /// @notice executes predefined settlement callback logic using parameters from data
    /// @param data The encoded data containing the necessary parameters for the settlement callback
    function executePostRouteCallback(
        bytes calldata data
    ) external payable onlyGluexRouter;
}
