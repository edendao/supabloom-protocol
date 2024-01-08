// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/// @title PropertyMap
/// @notice Map implementation with enumeration functions for bytes32 keys and values
/// @author Modified from Solidstate https://github.com/Solidstate-Network/solidstate-solidity
/// @author Modified from OpenZeppelin https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
library PropertyMap {
    error PropertyMap__IndexOutOfBounds();
    error PropertyMap__NonExistentID();

    struct Entry {
        bytes32 key;
        bytes32 value;
    }

    struct Map {
        Entry[] entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 key => uint256 index) _indexes;
    }

    function keys(
        Map storage map
    ) internal view returns (bytes32[] memory keysOut) {
        unchecked {
            uint256 i = map.entries.length;
            keysOut = new bytes32[](i);

            while (i-- != 0) {
                keysOut[i] = map.entries[i].key;
            }
        }
    }

    function values(
        Map storage map
    ) internal view returns (bytes32[] memory valuesOut) {
        unchecked {
            uint256 i = map.entries.length;
            valuesOut = new bytes32[](i);

            while (i-- != 0) {
                valuesOut[i] = map.entries[i].value;
            }
        }
    }

    function at(
        Map storage map,
        uint256 index
    ) internal view returns (bytes32, bytes32) {
        if (index >= map.entries.length) revert PropertyMap__IndexOutOfBounds();

        Entry storage entry = map.entries[index];
        return (entry.key, entry.value);
    }

    function contains(
        Map storage map,
        bytes32 key
    ) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    function length(Map storage map) internal view returns (uint256) {
        return map.entries.length;
    }

    function get(Map storage map, bytes32 key) internal view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) revert PropertyMap__NonExistentID();
        unchecked {
            return map.entries[keyIndex - 1].value;
        }
    }

    function set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map.entries.push(Entry(key, value));
            map._indexes[key] = map.entries.length;
            return true;
        } else {
            unchecked {
                map.entries[keyIndex - 1].value = value;
            }
            return false;
        }
    }

    function remove(Map storage map, bytes32 key) internal returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                Entry storage last = map.entries[map.entries.length - 1];

                // move last entry to now-vacant index
                map.entries[keyIndex - 1] = last;
                map._indexes[last.key] = keyIndex;
            }

            // clear last index
            map.entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}
