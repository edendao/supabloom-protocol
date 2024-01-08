// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {
    IERC1155,
    IERC1155Base
} from "@solidstate/contracts/token/ERC1155/base/IERC1155Base.sol";

import {
    BalanceMap,
    CAP1155Internal,
    CAP1155Storage
} from "./CAP1155Internal.sol";

/// @title ERC1155 implementation including enumerable and aggregate functions
/// @author CyrusOfEden
/// @author Derived from SolidState
abstract contract CAP1155Base is CAP1155Internal, IERC1155Base {
    using BalanceMap for BalanceMap.Map;

    /// @notice Returns the total supply of a given token
    /// @param id Token ID to query
    /// @return Total supply of the token
    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply(id);
    }

    /// @notice Returns an array of all balance entries for a given token
    /// @param id Token ID to query
    /// @return Array of balance entries (account, balance)
    function balancesOf(
        uint256 id
    ) public view returns (BalanceMap.Entry[] memory) {
        return CAP1155Storage.layout().balances[uint192(id)].entries;
    }

    /// @inheritdoc IERC1155
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256) {
        return _balanceOf(account, id);
    }

    /// @inheritdoc IERC1155
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert ERC1155Base__ArrayLengthMismatch();
        }

        mapping(uint192 => BalanceMap.Map) storage balances = CAP1155Storage
            .layout()
            .balances;

        uint256[] memory batchBalances = new uint256[](accounts.length);

        unchecked {
            for (uint256 i = accounts.length; i-- != 0; ) {
                batchBalances[i] = balances[uint192(ids[i])].get(accounts[i]);
            }
        }

        return batchBalances;
    }

    /// @inheritdoc IERC1155
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual returns (bool) {
        return CAP1155Storage.layout().operatorApprovals[account][operator];
    }

    /// @inheritdoc IERC1155
    function setApprovalForAll(address operator, bool status) public virtual {
        if (msg.sender == operator) revert ERC1155Base__SelfApproval();
        CAP1155Storage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }

    /// @inheritdoc IERC1155
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert ERC1155Base__NotOwnerOrApproved();
        }

        _safeTransfer(msg.sender, from, to, id, amount, data);
    }

    /// @inheritdoc IERC1155
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert ERC1155Base__NotOwnerOrApproved();
        }

        _safeTransferBatch(msg.sender, from, to, ids, amounts, data);
    }
}
