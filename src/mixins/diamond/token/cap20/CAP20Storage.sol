// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import { BalanceMap } from "~/libraries/BalanceMap.sol";

library CAP20Storage {
    struct Layout {
        uint256 initialChainID;
        bytes32 initialDomainSeparator;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        BalanceMap.Map balances;
        mapping(address => mapping(address => uint64)) allowance;
        mapping(address => uint256) nonces;
    }

    uint256 internal constant STORAGE_SLOT =
        uint256(keccak256("cap20.storage")) - 1;

    function layout() internal pure returns (Layout storage l) {
        uint256 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
