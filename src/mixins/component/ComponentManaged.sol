// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { Auth, IAuthority } from "~/mixins/diamond/auth/Auth.sol";
import { Withdrawable } from "~/mixins/diamond/Withdrawable.sol";
import { Components } from "~/components/Components.sol";

import { ComponentInternal } from "./ComponentInternal.sol";

abstract contract ComponentManaged is Auth, Withdrawable, ComponentInternal {
    function _setComponentsAndAuthority(Components c) internal {
        super._setComponents(c);
        _setAuthority(IAuthority(c.getComponent("acl")));
    }
}
