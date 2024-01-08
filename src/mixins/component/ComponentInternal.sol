// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { Components } from "~/components/Components.sol";
import { ComponentStorage } from "./ComponentStorage.sol";

abstract contract ComponentInternal {
    function _components() internal view returns (Components) {
        return ComponentStorage.layout().components;
    }

    function _setComponents(Components c) internal {
        ComponentStorage.layout().components = c;
    }
}
