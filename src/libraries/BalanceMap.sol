// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/// @title BalanceMap
/// @notice Map implementation with enumeration functions for address keys and uint64 values
/// @author Modified from Solidstate https://github.com/Solidstate-Network/solidstate-solidity
/// @author Modified from OpenZeppelin https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
library BalanceMap {
    error BalanceMap__IndexOutOfBounds();
    error BalanceMap__AddressNotFound();

    struct Entry {
        address key;
        uint64 value;
    }

    struct Map {
        Entry[] entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(address key => uint256 index) _indexes;
    }

    function keys(Map storage map) internal view returns (address[] memory keysOut) {
        unchecked {
            uint256 i = map.entries.length;
            keysOut = new address[](i);

            while (i-- != 0) {
                keysOut[i] = map.entries[i].key;
            }
        }
    }

    function values(Map storage map) internal view returns (uint64[] memory valuesOut) {
        unchecked {
            uint256 i = map.entries.length;
            valuesOut = new uint64[](i);

            while (i-- != 0) {
                valuesOut[i] = map.entries[i].value;
            }
        }
    }

    function at(Map storage map, uint64 index) internal view returns (Entry storage) {
        if (index >= map.entries.length) {
            revert BalanceMap__IndexOutOfBounds();
        }

        return map.entries[index];
    }

    function contains(Map storage map, address key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    function length(Map storage map) internal view returns (uint256) {
        return map.entries.length;
    }

    function _getEntry(Map storage map, uint256 index) internal view returns (Entry storage) {
        unchecked {
            return map.entries[index - 1];
        }
    }

    function getEntry(Map storage map, address key) internal view returns (Entry storage) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) {
            revert BalanceMap__AddressNotFound();
        }
        return _getEntry(map, keyIndex);
    }

    function get(Map storage map, address key) internal view returns (uint64) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) {
            revert BalanceMap__AddressNotFound();
        }
        return _getEntry(map, keyIndex).value;
    }

    function set(Map storage map, address key, uint64 value) internal returns (bool inserted) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            _getEntry(map, keyIndex).value = value;
            inserted = false;
        } else {
            map.entries.push(Entry({key: key, value: value}));
            map._indexes[key] = map.entries.length;
            inserted = true;
        }
    }

    function add(Map storage map, address key, uint64 value) internal returns (bool inserted) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            _getEntry(map, keyIndex).value += value;
            inserted = false;
        } else {
            map.entries.push(Entry({key: key, value: value}));
            map._indexes[key] = map.entries.length;
            inserted = true;
        }
    }

    function subtract(Map storage map, address key, uint64 value) internal returns (bool removed) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            revert BalanceMap__AddressNotFound();
        }

        Entry storage entry = map.entries[keyIndex - 1];
        if (entry.value != value) {
            entry.value -= value;
            removed = false;
        } else {
            unchecked {
                Entry storage last = map.entries[map.entries.length - 1];

                // move last entry to now-vacant index
                map.entries[keyIndex - 1] = last;
                map._indexes[last.key] = keyIndex;

                // clear last index
                map.entries.pop();
                delete map._indexes[key];
            }

            removed = true;
        }
    }

    function remove(Map storage map, address key) internal returns (bool removed) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            removed = false;
        } else {
            unchecked {
                Entry storage last = map.entries[map.entries.length - 1];

                // move last entry to now-vacant index
                map.entries[keyIndex - 1] = last;
                map._indexes[last.key] = keyIndex;
            }

            // clear last index
            map.entries.pop();
            delete map._indexes[key];

            removed = true;
        }
    }
}
