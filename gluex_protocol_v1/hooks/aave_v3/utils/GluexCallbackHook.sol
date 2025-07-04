// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title GluexCallbackHook
/// @notice This contract serves as a base for implementing structured settlements and hook callback logic.
abstract contract GluexCallbackHook {

    address public immutable gluexRouter;
    address public immutable hookTrigger;

    constructor(address _router, address _hookTrigger) {
        require(_router != address(0), "GlueX: zero router");
        gluexRouter = _router;
        hookTrigger = _hookTrigger; // The external contract that owns the underlying effective logic of the hook
    }

    // NOTE: This contract is designed to be inherited by other contracts that implement specific settlement and hook logic.
    // It provides the function signatures that must be implemented by derived contracts.
    
    // NOTE: Every GluexCallbackHook contract should be initialized with a specific version of GlueX's router contract as attribute.
    // This ensures the scope of the settlement and hook logic is confined to GlueX's ecosystem.

    modifier onlyGluexRouter() {
        // This modifier can be used to restrict access to functions to only GlueX's router contract.
        if (msg.sender != gluexRouter) revert("GlueX: unauthorized router callback caller");
        _;
    }

    modifier onlyHookTrigger() {
        // This modifier can be used to restrict access to functions to only GlueX's router contract.
        if (msg.sender != hookTrigger) revert("GlueX: unauthorized trigger callback caller");
        _;
    }

    /// @notice executes a structured settlement using the provided hook parameters
    /// @param hookParams The encoded parameters for the structured settlement
    /// @dev The hookParams should be structured in a way that the contract can decode and use them to execute the settlement logic
    /// @dev This function is payable, allowing it to receive Ether if needed for the settlement execution
    /// @dev The function should handle the logic defined in the structured settlement, which may include interacting with other contracts or performing state changes
    function executeStructuredSettlement(
        bytes calldata hookParams,
    ) external payable virtual;

    /// @notice executes predefined hook callback logic using parameters from data. Never implement without `onlyGluexRouter` modifier!
    /// @param data The encoded data containing the necessary parameters for the hook callback
    /// @dev The data should be encoded in a way that the contract can decode it to execute the hook logic
    /// @dev This function is payable, allowing it to receive Ether if needed for the hook execution
    /// @dev The function should handle the logic defined in the hook callback, which may include interacting with other contracts or performing state changes
    function executePreHookCallback(
        bytes calldata data,
    ) external payable virtual onlyGluexRouter;

    /// @notice executes predefined hook callback logic using parameters from data. Never implement without `onlyGluexRouter` modifier!
    /// @param data The encoded data containing the necessary parameters for the hook callback
    /// @dev The data should be encoded in a way that the contract can decode it to execute the hook logic
    /// @dev This function is payable, allowing it to receive Ether if needed for the hook execution
    /// @dev The function should handle the logic defined in the hook callback, which may include interacting with other contracts or performing state changes
    function executePostHookCallback(
        bytes calldata data,
    ) external payable virtual onlyGluexRouter;
}
