// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import { AuthStorage, IAuthority } from "./AuthStorage.sol";

abstract contract AuthInternal {
    error Auth__NotAuthorized();

    modifier requiresAuth() {
        if (!_isAuthorized(msg.sender, msg.data)) {
            revert Auth__NotAuthorized();
        }

        _;
    }

    function _isAuthorized(
        address user,
        bytes calldata data
    ) internal view virtual returns (bool) {
        return _authority().canCall(user, address(this), data);
    }

    function _authority() internal view returns (IAuthority) {
        return AuthStorage.layout().authority;
    }

    function _setAuthority(address newAuthority) internal {
        _setAuthority(IAuthority(newAuthority));
    }

    function _setAuthority(IAuthority newAuthority) internal {
        AuthStorage.layout().authority = newAuthority;
        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    event AuthorityUpdated(
        address indexed user,
        IAuthority indexed newAuthority
    );
}
