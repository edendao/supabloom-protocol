// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import {
    IERC20BaseInternal
} from "@solidstate/contracts/token/ERC20/base/IERC20BaseInternal.sol";
import {
    IERC20MetadataInternal
} from "@solidstate/contracts/token/ERC20/metadata/IERC20MetadataInternal.sol";
import {
    IERC20PermitInternal
} from "@solidstate/contracts/token/ERC20/permit/IERC20PermitInternal.sol";

import { CAP20Storage, BalanceMap } from "./CAP20Storage.sol";

abstract contract CAP20Internal is
    IERC20BaseInternal,
    IERC20MetadataInternal,
    IERC20PermitInternal
{
    using BalanceMap for BalanceMap.Map;

    function _name() internal view returns (string memory) {
        return CAP20Storage.layout().name;
    }

    function _setName(string memory name_) internal virtual {
        CAP20Storage.Layout storage l = CAP20Storage.layout();
        l.name = name_;
        l.initialChainID = block.chainid;
        l.initialDomainSeparator = _computeDomainSeparator(name_);
    }

    function _symbol() internal view returns (string memory) {
        return CAP20Storage.layout().symbol;
    }

    function _setSymbol(string memory symbol_) internal {
        CAP20Storage.Layout storage l = CAP20Storage.layout();
        l.symbol = symbol_;
    }

    function _decimals() internal view returns (uint8) {
        return CAP20Storage.layout().decimals;
    }

    function _setDecimals(uint8 decimals_) internal {
        CAP20Storage.Layout storage l = CAP20Storage.layout();
        l.decimals = decimals_;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint64 amount) internal virtual {
        CAP20Storage.Layout storage l = CAP20Storage.layout();

        l.totalSupply += amount;
        l.balances.add(to, amount);

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint64 amount) internal virtual {
        CAP20Storage.Layout storage l = CAP20Storage.layout();

        l.balances.subtract(from, amount);
        unchecked {
            l.totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/
    function _approve(
        address account,
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        CAP20Storage.layout().allowance[account][spender] = uint64(amount);

        emit Approval(account, spender, amount);

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint64 amount
    ) internal virtual returns (bool) {
        BalanceMap.Map storage balances = CAP20Storage.layout().balances;

        balances.subtract(from, amount);
        balances.add(to, amount);

        emit Transfer(from, to, amount);

        return true;
    }

    function _transferFrom(
        address from,
        address to,
        uint64 amount
    ) internal virtual returns (bool) {
        CAP20Storage.Layout storage l = CAP20Storage.layout();

        uint64 allowed = l.allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint64).max) {
            l.allowance[from][msg.sender] = allowed - amount;
        }

        BalanceMap.Map storage balances = l.balances;

        balances.subtract(from, amount);
        balances.add(to, amount);

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL PERMIT LOGIC
    //////////////////////////////////////////////////////////////*/
    function _computeDomainSeparator(
        string memory name
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _domainSeparator() internal view virtual returns (bytes32) {
        CAP20Storage.Layout storage l = CAP20Storage.layout();
        if (block.chainid == l.initialChainID) {
            return l.initialDomainSeparator;
        } else {
            return _computeDomainSeparator(l.name);
        }
    }

    function _permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual {
        if (deadline < block.timestamp) {
            revert ERC20Permit__ExpiredDeadline();
        }

        CAP20Storage.Layout storage l = CAP20Storage.layout();

        bytes32 hashStruct;
        uint256 nonce = l.nonces[owner];

        assembly {
            // Load free memory pointer
            let pointer := mload(64)

            // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
            mstore(
                pointer,
                0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9
            )
            mstore(add(pointer, 32), owner)
            mstore(add(pointer, 64), spender)
            mstore(add(pointer, 96), amount)
            mstore(add(pointer, 128), nonce)
            mstore(add(pointer, 160), deadline)

            hashStruct := keccak256(pointer, 192)
        }

        bytes32 domainSeparator = _domainSeparator();
        bytes32 digest;

        assembly {
            // Load free memory pointer
            let pointer := mload(64)

            mstore(
                pointer,
                0x1901000000000000000000000000000000000000000000000000000000000000
            ) // EIP191 header
            mstore(add(pointer, 2), domainSeparator) // EIP712 domain hash
            mstore(add(pointer, 34), hashStruct) // Hash of struct

            digest := keccak256(pointer, 66)
        }

        if (owner != ecrecover(digest, v, r, s)) {
            revert ERC20Permit__InvalidSignature();
        }

        l.nonces[owner] += 1;
        _approve(owner, spender, amount);
    }
}
