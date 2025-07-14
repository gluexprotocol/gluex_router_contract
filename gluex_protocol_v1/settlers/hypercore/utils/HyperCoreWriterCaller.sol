// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ICoreWriter} from "../interfaces/ICoreWriter.sol";

/// @title HyperCore Writer
/// @notice This contract serves as a base for any structured settlement that swaps assets on HyperEVM and deposits them into HyperCore atomically.
abstract contract HyperCoreWriterCaller {

    address public immutable hyperCoreWriter = 0x3333333333333333333333333333333333333333;

    function limitOrder(uint32 asset, bool isBuy, uint64 limitPx, uint64 sz, bool reduceOnly, uint8 encodedTif, uint128 cloid) external {
        bytes memory encodedAction = abi.encode(asset, isBuy, limitPx, sz, reduceOnly, encodedTif, cloid);
        bytes memory data = new bytes(4 + encodedAction.length);
        data[0] = 0x01;
        data[1] = 0x00;
        data[2] = 0x00;
        data[3] = 0x01;
        for (uint256 i = 0; i < encodedAction.length; i++) {
            data[4 + i] = encodedAction[i];
        }
        ICoreWriter(hyperCoreWriter).sendRawAction(data);
    }


    function vaultTransfer(address vault, bool isDeposit, uint64 usd) external {
        bytes memory encodedAction = abi.encode(vault, isDeposit, usd);
        bytes memory data = new bytes(4 + encodedAction.length);
        data[0] = 0x01;
        data[1] = 0x00;
        data[2] = 0x00;
        data[3] = 0x02;
        for (uint256 i = 0; i < encodedAction.length; i++) {
            data[4 + i] = encodedAction[i];
        }
        ICoreWriter(hyperCoreWriter).sendRawAction(data);
    }

    function tokenDelegate(address validator, uint64 amount, bool isUndelegate) external {
        bytes memory encodedAction = abi.encode(validator, amount, isUndelegate);
        bytes memory data = new bytes(4 + encodedAction.length);
        data[0] = 0x01;
        data[1] = 0x00;
        data[2] = 0x00;
        data[3] = 0x03;
        for (uint256 i = 0; i < encodedAction.length; i++) {
            data[4 + i] = encodedAction[i];
        }
        ICoreWriter(hyperCoreWriter).sendRawAction(data);
    }

    function stakingDeposit(uint64 amount) external {
        bytes memory encodedAction = abi.encode(amount);
        bytes memory data = new bytes(4 + encodedAction.length);
        data[0] = 0x01;
        data[1] = 0x00;
        data[2] = 0x00;
        data[3] = 0x04;
        for (uint256 i = 0; i < encodedAction.length; i++) {
            data[4 + i] = encodedAction[i];
        }
        ICoreWriter(hyperCoreWriter).sendRawAction(data);
    }

    function stakingWithdraw(uint64 amount) external {
        bytes memory encodedAction = abi.encode(amount);
        bytes memory data = new bytes(4 + encodedAction.length);
        data[0] = 0x01;
        data[1] = 0x00;
        data[2] = 0x00;
        data[3] = 0x05;
        for (uint256 i = 0; i < encodedAction.length; i++) {
            data[4 + i] = encodedAction[i];
        }
        ICoreWriter(hyperCoreWriter).sendRawAction(data);
    }

    // @notice Spont send to hyperCore
    /// @param hyperCoreReceiver The address of the HyperCore receiver
    /// @param hyperCoreTokenId The token ID in HyperCore to send
    /// @param amount The amount of the token to send
    function spotSend(address hyperCoreReceiver, uint64 hyperCoreTokenId, uint64 amount) external {
        bytes memory encodedAction = abi.encode(hyperCoreReceiver, hyperCoreTokenId, amount);
        bytes memory data = new bytes(4 + encodedAction.length);
        data[0] = 0x01;
        data[1] = 0x00;
        data[2] = 0x00;
        data[3] = 0x06;
        for (uint256 i = 0; i < encodedAction.length; i++) {
            data[4 + i] = encodedAction[i];
        }
        ICoreWriter(hyperCoreWriter).sendRawAction(data);
    }

    function usdClassTransfer(uint64 ntl, bool toPerp) external {
        bytes memory encodedAction = abi.encode(ntl, toPerp);
        bytes memory data = new bytes(4 + encodedAction.length);
        data[0] = 0x01;
        data[1] = 0x00;
        data[2] = 0x00;
        data[3] = 0x07;
        for (uint256 i = 0; i < encodedAction.length; i++) {
            data[4 + i] = encodedAction[i];
        }
        ICoreWriter(hyperCoreWriter).sendRawAction(data);
    }
}
