// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { IAuthority } from "~/interfaces/IAuthority.sol";

library AuthStorage {
    struct Layout {
        IAuthority authority;
    }

    uint256 internal constant STORAGE_SLOT =
        uint256(keccak256("cap.auth.storage")) - 1;

    function layout() internal pure returns (Layout storage l) {
        uint256 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
