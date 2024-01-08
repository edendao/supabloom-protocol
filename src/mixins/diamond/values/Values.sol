// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { AuthInternal } from "~/mixins/diamond/auth/AuthInternal.sol";

import { ValuesInternal } from "./ValuesInternal.sol";

contract Values is AuthInternal, ValuesInternal {
    function valueOf(
        bytes4 selector,
        uint256 units
    ) external view returns (uint256) {
        return _getValue(selector, units);
    }

    function setSelectorValues(
        bytes4[] calldata selectors,
        uint256[] calldata factors
    ) external requiresAuth {
        _setSelectorFactors(selectors, factors);
    }
}
