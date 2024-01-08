// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { Components } from "~/components/Components.sol";

library ComponentStorage {
    struct Layout {
        Components components;
        mapping(uint256 slot => bool) initialized;
    }

    uint256 internal constant STORAGE_SLOT =
        uint256(keccak256("cap.component.storage")) - 1;

    function layout() internal pure returns (Layout storage l) {
        uint256 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
