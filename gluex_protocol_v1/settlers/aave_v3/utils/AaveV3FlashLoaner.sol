// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "../../../interfaces/IERC20.sol";
import {SafeERC20} from "../../../lib/SafeERC20.sol"; 

/// @title AaveV3FlashLoaner
/// @notice This contract serves as a base for any structured settlement that needs to implement Aave V3 flash loan functionality.
abstract contract AaveV3FlashLoaner {
    using SafeERC20 for IERC20;

    function executeOperation(
        IERC20 asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external virtual returns (bool); 
}
