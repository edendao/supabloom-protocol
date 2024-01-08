// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {
    ERC165Base
} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import { ICAP721Base, IERC721Base, IERC721Metadata } from "./ICAP721Base.sol";

import { CAP721Internal } from "./CAP721Internal.sol";

abstract contract CAP721Base is ERC165Base, CAP721Internal, ICAP721Base {
    function idRange() external view returns (uint64, uint64) {
        return _idRange();
    }

    /// ================ IERC721Base ===============
    function ownerOf(uint256 id) external view override returns (address) {
        return _ownerOf(id);
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balanceOf(account);
    }

    function approve(address operator, uint256 id) external payable override {
        _approve(operator, id);
    }

    function getApproved(uint256 id) external view override returns (address) {
        return _getApproved(id);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) external override {
        _setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) external view override returns (bool) {
        return _isApprovedForAll(account, operator);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external payable override {
        _transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external payable override {
        _safeTransferFrom(from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) external payable override {
        _safeTransferFrom(from, to, id, data);
    }

    /// =============== IERC721Metadata ==============
    function name() external view override returns (string memory) {
        return _name();
    }

    function symbol() external view override returns (string memory) {
        return _symbol();
    }

    function tokenURI(
        uint256 id
    ) external view override returns (string memory) {
        return _tokenURI(id);
    }

    function setTokenURI(uint256 id, string calldata uri) external payable {
        _setTokenURI(id, uri);

        emit MetadataUpdate(id);
        emit URI(uri, id);
    }
}
