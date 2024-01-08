// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { BalanceMap } from "~/libraries/BalanceMap.sol";

/// @dev Storage layout for ERC1155 compliant token implementation with snapshots
library CAP1155Storage {
    using BalanceMap for BalanceMap.Map;

    struct Layout {
        mapping(address account => mapping(address operator => bool isApproved)) operatorApprovals;
        // Enumerable
        mapping(uint256 tokenID => uint64) totalSupply;
        mapping(uint256 tokenID => BalanceMap.Map) balances;
    }

    uint256 private constant STORAGE_SLOT =
        uint256(keccak256("cap1155.storage")) - 1;

    function layout() internal pure returns (Layout storage l) {
        uint256 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
