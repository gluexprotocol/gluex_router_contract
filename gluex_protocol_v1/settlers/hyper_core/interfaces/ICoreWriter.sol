// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for making arbitrary calls
interface ICoreWriter{
    
    function sendRawAction(bytes calldata data) external virtual;
}
