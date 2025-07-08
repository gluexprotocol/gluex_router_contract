// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title GluexSettler
/// @notice This contract serves as a base for implementing structured settlements and settlement callback logic.
abstract contract GluexSettler {

    address public immutable gluexRouter;
    address public immutable settlementTrigger;

    constructor(address _router, address _settlementTrigger) {
        require(_router != address(0), "GlueX: zero router");
        gluexRouter = _router;
        settlementTrigger = _settlementTrigger; // The external contract that owns the underlying effective logic of the settlement
    }

    // NOTE: This contract is designed to be inherited by other contracts that implement specific settlement and settlement logic.
    // It provides the function signatures that must be implemented by derived contracts.
    
    // NOTE: Every GluexSettler contract should be initialized with a specific version of GlueX's router contract as attribute.
    // This ensures the scope of the settlement logic is confined to GlueX's ecosystem.

    modifier onlyGluexRouter() {
        // This modifier can be used to restrict access to functions to only GlueX's router contract.
        if (msg.sender != gluexRouter) revert("GlueX: unauthorized router callback caller");
        _;
    }

    modifier onlySettlementTrigger() {
        // This modifier can be used to restrict access to functions to only GlueX's router contract.
        if (msg.sender != settlementTrigger) revert("GlueX: unauthorized settlement callback caller");
        _;
    }

    /// @notice executes a structured settlement using the provided settlement parameters
    /// @param settlementParams The encoded parameters for the structured settlement
    /// @dev The settlement should be structured in a way that the contract can decode and use them to execute the settlement logic
    /// @dev This function is payable, allowing it to receive Ether if needed for the settlement execution
    /// @dev The function should handle the logic defined in the structured settlement, which may include interacting with other contracts or performing state changes
    function executeStructuredSettlement(
        bytes calldata settlementParams,
    ) external payable virtual;

    /// @notice executes predefined settlement callback logic using parameters from data. Never implement without `onlyGluexRouter` modifier!
    /// @param data The encoded data containing the necessary parameters for the settlement callback
    /// @dev The data should be encoded in a way that the contract can decode it to execute the settlement logic
    /// @dev This function is payable, allowing it to receive Ether if needed for the settlement execution
    /// @dev The function should handle the logic defined in the settlement callback, which may include interacting with other contracts or performing state changes
    function executePreRouteCallback(
        bytes calldata data,
    ) external payable virtual onlyGluexRouter;

    /// @notice executes predefined settlement callback logic using parameters from data. Never implement without `onlyGluexRouter` modifier!
    /// @param data The encoded data containing the necessary parameters for the settlement callback
    /// @dev The data should be encoded in a way that the contract can decode it to execute the settlement logic
    /// @dev This function is payable, allowing it to receive Ether if needed for the settlement execution
    /// @dev The function should handle the logic defined in the settlement callback, which may include interacting with other contracts or performing state changes
    function executePostRouteCallback(
        bytes calldata data,
    ) external payable virtual onlyGluexRouter;
}
