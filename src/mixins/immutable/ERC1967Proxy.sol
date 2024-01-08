// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { Delegator } from "./Delegator.sol";

contract ERC1967Proxy is Delegator {
    error ERC1967Proxy__InvalidImplementation();
    event Upgraded(address indexed implementation);

    struct Address {
        address value;
    }

    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address impl) {
        _setImplementation(impl);
    }

    function _getImplementation() internal virtual returns (address) {
        Address storage impl;
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            impl.slot := slot
        }
        return impl.value;
    }

    function _setImplementation(address to) internal {
        if (to == address(0) || to.code.length == 0) {
            revert ERC1967Proxy__InvalidImplementation();
        }

        Address storage impl;
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            impl.slot := slot
        }
        impl.value = to;
        emit Upgraded(to);
    }

    receive() external payable {
        _delegate(_getImplementation());
    }

    fallback() external payable {
        _delegate(_getImplementation());
    }
}
