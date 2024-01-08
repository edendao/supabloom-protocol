// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { ComponentStorage } from "./ComponentStorage.sol";

abstract contract ComponentInitializable {
    error ComponentInitializable__AlreadyInitialized();

    modifier initializer(uint256 slot) {
        mapping(uint256 => bool) storage initialized = ComponentStorage
            .layout()
            .initialized;

        if (initialized[slot]) {
            revert ComponentInitializable__AlreadyInitialized();
        }

        _;

        initialized[slot] = true;
    }
}
