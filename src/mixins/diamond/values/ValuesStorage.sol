// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

library ValuesStorage {
    struct Layout {
        mapping(bytes4 sig => uint256 amount) selectors;
    }

    uint256 private constant STORAGE_SLOT =
        uint256(keccak256("cap.amounts.storage")) - 1;

    function layout() internal pure returns (Layout storage l) {
        uint256 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function getValue(
        Layout storage l,
        bytes4 selector
    ) internal view returns (uint256) {
        mapping(bytes4 => uint256) storage selectors = l.selectors;

        uint256 value = selectors[selector];
        if (value == 0) {
            return selectors[0x0000];
        }

        return value;
    }
}
