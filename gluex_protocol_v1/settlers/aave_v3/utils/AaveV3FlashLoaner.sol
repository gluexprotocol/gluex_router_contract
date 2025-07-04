// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title AaveV3FlashLoaner
/// @notice This contract serves as a base for any structured settlement that needs to implement Aave V3 flash loan functionality.
abstract contract AaveV3FlashLoaner {

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external virtual returns (bool); 
}
