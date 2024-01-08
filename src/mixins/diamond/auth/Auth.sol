// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import { AuthInternal, IAuthority } from "./AuthInternal.sol";

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author CyrusOfEden
/// @author Modified from Solmate (https://github.com/transmissions11/solmacap/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth is AuthInternal {
    function getAuthority() external view returns (IAuthority) {
        return _authority();
    }
}
