// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { SafeCastLib } from "solady/utils/SafeCastLib.sol";

import { IAuthority } from "~/interfaces/IAuthority.sol";
import { BalanceMap } from "~/libraries/BalanceMap.sol";

library CAP721Storage {
    using SafeCastLib for uint256;
    using BalanceMap for BalanceMap.Map;

    struct Layout {
        string name;
        string symbol;
        uint64 idOffset;
        uint64 idCounter;
        uint64 idLimit;
        mapping(address account => mapping(address operator => bool)) isApprovedForAll;
        BalanceMap.Map balances;
        mapping(uint64 id => address) operators;
        mapping(uint64 id => address) owners;
        mapping(uint64 id => string) uris;
    }

    uint256 internal constant STORAGE_SLOT =
        uint256(keccak256("cap721.storage")) - 1;

    function layout() internal pure returns (Layout storage l) {
        uint256 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function tokenURI(
        Layout storage l,
        uint256 id
    ) internal view returns (string memory uri) {
        return l.uris[id.toUint64()];
    }

    function ownerOf(
        Layout storage l,
        uint256 id
    ) internal view returns (address) {
        return l.owners[id.toUint64()];
    }

    function balanceOf(
        Layout storage l,
        address owner
    ) internal view returns (uint256) {
        return uint256(l.balances.get(owner));
    }

    function getApproved(
        Layout storage l,
        uint256 id
    ) internal view returns (address) {
        return l.operators[id.toUint64()];
    }

    function approve(Layout storage l, uint256 id, address operator) internal {
        l.operators[id.toUint64()] = operator;
    }
}
