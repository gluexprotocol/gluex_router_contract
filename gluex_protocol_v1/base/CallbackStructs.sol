// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/**
 * @dev A generic structure defining the parameters for a callback.
 */
struct CallbackData {
    bytes data; // Encoded data for the callback hook
    uint256 value; // Value to be sent with the callback, if applicable
}
