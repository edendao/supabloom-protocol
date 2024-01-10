// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

abstract contract Initializable {
    error Initializable__AlreadyInitialized();

    uint256 private _initialized = 1;

    modifier initializer() {
        if (_initialized == 0) {
            revert Initializable__AlreadyInitialized();
        }
        _;

        _initialized = 0;
    }
}
