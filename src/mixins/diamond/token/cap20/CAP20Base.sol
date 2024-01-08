// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import {
    IERC20Base
} from "@solidstate/contracts/token/ERC20/base/IERC20Base.sol";
import {
    IERC20Metadata
} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import {
    IERC20Permit
} from "@solidstate/contracts/token/ERC20/permit/IERC20Permit.sol";

import { CAP20Internal, CAP20Storage, BalanceMap } from "./CAP20Internal.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author CyrusOfEden
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract CAP20Base is
    CAP20Internal,
    IERC20Base,
    IERC20Metadata,
    IERC20Permit
{
    using BalanceMap for BalanceMap.Map;

    function name() public view returns (string memory) {
        return _name();
    }

    function symbol() public view returns (string memory) {
        return _symbol();
    }

    function decimals() public view returns (uint8) {
        return _decimals();
    }

    function totalSupply() public view returns (uint256) {
        return CAP20Storage.layout().totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return uint256(CAP20Storage.layout().balances.get(account));
    }

    function balances() public view returns (BalanceMap.Entry[] memory) {
        return CAP20Storage.layout().balances.entries;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return uint256(CAP20Storage.layout().allowance[owner][spender]);
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        return _approve(msg.sender, spender, uint64(amount));
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        return _transfer(msg.sender, to, uint64(amount));
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        return _transferFrom(from, to, uint64(amount));
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparator();
    }

    function nonces(address owner) public view returns (uint256) {
        return CAP20Storage.layout().nonces[owner];
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        _permit(owner, spender, amount, deadline, v, r, s);
    }
}
