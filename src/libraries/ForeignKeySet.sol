// SPDX-License-Identifier: BUSL
pragma solidity 0.8.21;

/**
 * @title Set implementation with enumeration functions
 * @dev CyrusOfEden
 * @dev derived from https://github.com/solidstate-solidity (MIT license)
 */
library ForeignKeySet {
    error ForeignKeySet__IndexOutOfBounds();

    struct Set {
        uint64[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(uint64 key => uint256 index) _indexes;
    }

    function values(Set storage set) public view returns (uint64[] memory) {
        return set._values;
    }

    function at(Set storage set, uint256 index) public view returns (uint64) {
        if (index >= set._values.length) {
            revert ForeignKeySet__IndexOutOfBounds();
        }
        return set._values[index];
    }

    function contains(
        Set storage set,
        uint64 value
    ) public view returns (bool) {
        return set._indexes[value] != 0;
    }

    function indexOf(
        Set storage set,
        uint64 value
    ) public view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function count(Set storage set) public view returns (uint256) {
        return set._values.length;
    }

    function add(Set storage set, uint64 value) public returns (bool added) {
        if (set._indexes[value] == 0) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            added = true;
        }
    }

    function remove(
        Set storage set,
        uint64 value
    ) public returns (bool removed) {
        unchecked {
            uint256 valueIndex = set._indexes[value];

            if (valueIndex != 0) {
                uint64 last = set._values[set._values.length - 1];

                // move last value to now-vacant index
                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }

            // clear last index
            set._values.pop();
            delete set._indexes[value];

            removed = true;
        }
    }
}
