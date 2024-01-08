// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC721 } from "forge-std/interfaces/IERC721.sol";
import { IERC1155 } from "forge-std/interfaces/IERC1155.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { AuthInternal } from "./auth/AuthInternal.sol";

abstract contract Withdrawable is AuthInternal {
    function withdraw(address to, uint256 amount) external requiresAuth {
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function withdrawFungibleToken(
        address to,
        IERC20 token,
        uint256 amount
    ) external requiresAuth {
        SafeTransferLib.safeTransfer(address(token), to, amount);
    }

    function withdrawNonFungibleToken(
        address to,
        IERC721 token,
        uint256 id
    ) external requiresAuth {
        token.safeTransferFrom(address(this), to, id);
    }

    function withdrawTokens(
        address to,
        IERC1155 token,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external requiresAuth {
        token.safeBatchTransferFrom(address(this), to, ids, amounts, "");
    }
}
