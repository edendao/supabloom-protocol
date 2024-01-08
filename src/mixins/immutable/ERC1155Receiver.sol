// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {
    IERC1155Receiver
} from "@solidstate/contracts/interfaces/IERC1155Receiver.sol";

abstract contract ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
