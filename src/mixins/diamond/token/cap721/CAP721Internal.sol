// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {
    IERC721Receiver
} from "@solidstate/contracts/interfaces/IERC721Receiver.sol";

import { CAP721Storage, BalanceMap } from "./CAP721Storage.sol";
import { ICAP721Internal } from "./ICAP721Internal.sol";

/// @title CAP721Internal
/// @notice An ERC721 with CAP token IDs
contract CAP721Internal is ICAP721Internal {
    using CAP721Storage for CAP721Storage.Layout;
    using BalanceMap for BalanceMap.Map;

    error CAP721__MintLimit();
    error CAP721__InvalidURI();

    function _setName(string memory name_) internal {
        CAP721Storage.layout().name = name_;
    }

    function _setSymbol(string memory symbol_) internal {
        CAP721Storage.layout().symbol = symbol_;
    }

    function _setIDOffset(uint64 idOffset_) internal {
        CAP721Storage.layout().idOffset = idOffset_;
    }

    function _setIDLimit(uint64 idLimit_) internal {
        CAP721Storage.layout().idLimit = idLimit_;
    }

    function _mint(
        address to,
        string calldata uri
    ) internal returns (uint64 id) {
        if (bytes(uri).length == 0) {
            revert CAP721__InvalidURI();
        }

        CAP721Storage.Layout storage l = CAP721Storage.layout();

        id = l.idOffset + (++l.idCounter);
        if (id > l.idLimit) {
            revert CAP721__MintLimit();
        }

        l.owners[id] = to;
        l.balances.add(to, 1);
        l.uris[id] = uri;

        emit Transfer(address(0), to, id);
        emit MetadataUpdate(id);
        emit URI(uri, id);
    }

    function _ownerOf(uint256 id) internal view returns (address owner) {
        owner = CAP721Storage.layout().ownerOf(id);
        if (owner == address(0)) {
            revert ERC721Base__InvalidOwner();
        }
    }

    function _balanceOf(address account) internal view returns (uint256) {
        if (account == address(0)) {
            revert ERC721Base__BalanceQueryZeroAddress();
        }
        return CAP721Storage.layout().balanceOf(account);
    }

    function _getApproved(uint256 id) internal view returns (address) {
        CAP721Storage.Layout storage l = CAP721Storage.layout();
        if (l.ownerOf(id) == address(0)) {
            revert ERC721Base__NonExistentToken();
        }
        return l.getApproved(id);
    }

    function _approve(address operator, uint256 id) internal {
        CAP721Storage.Layout storage l = CAP721Storage.layout();

        address owner = l.ownerOf(id);
        if (owner == address(0)) {
            revert ERC721Base__NonExistentToken();
        }
        if (msg.sender != owner && !l.isApprovedForAll[owner][msg.sender]) {
            revert ERC721Base__NotOwnerOrApproved();
        }

        l.approve(id, owner);
        emit Approval(owner, operator, id);
    }

    function _isApprovedForAll(
        address account,
        address operator
    ) internal view returns (bool) {
        return CAP721Storage.layout().isApprovedForAll[account][operator];
    }

    function _setApprovalForAll(address operator, bool approved) internal {
        CAP721Storage.layout().isApprovedForAll[msg.sender][
            operator
        ] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _transferFrom(address from, address to, uint256 id) internal {
        if (to == address(0)) {
            revert ERC721Base__TransferToZeroAddress();
        }

        CAP721Storage.Layout storage l = CAP721Storage.layout();

        address owner = l.ownerOf(id);
        if (owner == address(0)) {
            revert ERC721Base__NonExistentToken();
        }
        if (owner != from) {
            revert ERC721Base__NotTokenOwner();
        }

        if (
            msg.sender != from &&
            msg.sender != l.getApproved(id) &&
            !l.isApprovedForAll[from][msg.sender]
        ) {
            revert ERC721Base__NotOwnerOrApproved();
        }

        l.balances.subtract(from, 1);
        l.balances.add(to, 1);

        l.owners[uint64(id)] = to;
        l.approve(id, address(0));

        emit Approval(owner, address(0), id);
        emit Transfer(from, to, id);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal {
        _transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            IERC721Receiver.onERC721Received.selector
        ) {
            revert ERC721Base__ERC721ReceiverNotImplemented();
        }
    }

    function _name() internal view returns (string memory) {
        return CAP721Storage.layout().name;
    }

    function _symbol() internal view returns (string memory) {
        return CAP721Storage.layout().symbol;
    }

    function _idRange() internal view returns (uint64, uint64) {
        CAP721Storage.Layout storage l = CAP721Storage.layout();
        return (l.idOffset, l.idLimit);
    }

    function _tokenURI(uint256 id) internal view returns (string memory uri) {
        uri = CAP721Storage.layout().tokenURI(id);
        if (bytes(uri).length == 0) {
            revert ERC721Base__NonExistentToken();
        }
    }

    function _setTokenURI(uint256 id, string calldata uri) internal {
        if (bytes(uri).length == 0) {
            revert CAP721__InvalidURI();
        }

        CAP721Storage.Layout storage l = CAP721Storage.layout();
        if (l.ownerOf(id) != msg.sender) {
            revert ERC721Base__NotTokenOwner();
        }
        l.uris[uint64(id)] = uri;
    }
}
