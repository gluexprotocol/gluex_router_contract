// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";

// @dev Struct to handle surplus and slippage calculations.
struct ShareCalculation {
    uint256 surplus;
    uint256 slippage;
    uint256 partnerShare;
    uint256 protocolShare;
}

// @dev This file contains the data structures used in the GlueX Router V1.2.
struct RouteDescription {
    IERC20 inputToken; // Token used as input for the route
    IERC20 outputToken; // Token received as output from the route
    address payable inputReceiver; // Address to receive the input token
    address payable outputReceiver; // Address to receive the output token
    address payable partnerAddress; // Address of the partner receiving surplus share
    uint256 inputAmount; // Amount of input token
    uint256 marginAmount; // Amount of margint to be provided by the user. Only considered when non-zero.
    uint256 outputAmount; // Optimizer output amount
    uint256 partnerFee; // Fee charged by the partner
    uint256 routingFee; // Fee charged for routing operation
    uint256 partnerSurplusShare; // Percentage (in bps) of surplus shared with the partner
    uint256 protocolSurplusShare; // Percentage (in bps) of surplus shared with GlueX
    uint256 partnerSlippageShare; // Percentage (in bps) of slippage shared with the partner
    uint256 protocolSlippageShare; // Percentage (in bps) of slippage shared with GlueX
    uint256 effectiveOutputAmount; // Effective output amount for the user
    uint256 minOutputAmount; // Minimum acceptable output amount
    bool isPermit2; // Whether to use Permit2 for token transfers
    bytes32 uniquePID; // Unique identifier for the partner
}

// @dev generic smart contract interaction
struct Interaction {
    address target;
    uint256 value;
    bytes callData;
}

/**
 * @dev A generic structure defining the parameters for a callback.
 */
struct CallbackData {
    bytes data; // Encoded data for the callback hook
    uint256 value; // Value to be sent with the callback, if applicable
}