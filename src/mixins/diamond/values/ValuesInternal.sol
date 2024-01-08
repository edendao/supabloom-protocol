// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { ValuesStorage } from "./ValuesStorage.sol";

abstract contract ValuesInternal {
    using ValuesStorage for ValuesStorage.Layout;

    error Values__ArrayLengthMismatch();
    error Values__InsufficientValue();

    event ValueSet(bytes4 indexed selector, uint256 value);

    modifier valuable() {
        _requireValue(msg.sig);
        _;
    }

    function _getValue(bytes4 sig) internal view returns (uint256) {
        return ValuesStorage.layout().getValue(sig);
    }

    function _getValue(
        bytes4 sig,
        uint256 scale
    ) internal view returns (uint256) {
        return _getValue(sig) * scale;
    }

    function _requireValue() internal {
        _requireValue(msg.sig);
    }

    function _requireValue(uint256 scale) internal {
        _requireValue(msg.sig, scale);
    }

    function _requireValue(bytes4 sig) internal {
        if (msg.value < _getValue(sig)) {
            revert Values__InsufficientValue();
        }
    }

    function _requireValue(bytes4 sig, uint256 scale) internal {
        if (msg.value < _getValue(sig, scale)) {
            revert Values__InsufficientValue();
        }
    }

    function _setSelectorFactors(
        bytes4[] calldata selectors,
        uint256[] calldata factors
    ) internal {
        unchecked {
            uint256 i = selectors.length;
            if (i != factors.length) {
                revert Values__ArrayLengthMismatch();
            }

            ValuesStorage.Layout storage l = ValuesStorage.layout();
            bytes4 selector;
            uint256 value;
            while (i-- != 0) {
                selector = selectors[i];
                value = factors[i];
                l.selectors[selector] = value;
                emit ValueSet(selector, value);
            }
        }
    }
}
