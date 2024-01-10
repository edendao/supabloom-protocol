// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import {AuthInternal} from "~/mixins/diamond/auth/AuthInternal.sol";

library AddressStorage {
    struct Layout {
        mapping(bytes32 key => address) addresses;
    }

    uint256 private constant STORAGE_SLOT = uint256(keccak256("cap.address.storage")) - 1;

    function layout() internal pure returns (Layout storage l) {
        uint256 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function getAddress(Layout storage l, bytes32 key) internal view returns (address) {
        return l.addresses[key];
    }

    function getAddresses(Layout storage l, bytes32 a, bytes32 b) internal view returns (address, address) {
        // Save SLOADs
        mapping(bytes32 => address) storage lookup = l.addresses;
        return (lookup[a], lookup[b]);
    }

    function getAddresses(Layout storage l, bytes32 a, bytes32 b, bytes32 c)
        internal
        view
        returns (address, address, address)
    {
        // Save SLOADs
        mapping(bytes32 => address) storage lookup = l.addresses;
        return (lookup[a], lookup[b], lookup[c]);
    }
}
