// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { ERC20Base } from "@solidstate/token/ERC20/base/ERC20Base.sol";
import {
    ERC20BaseInternal
} from "@solidstate/token/ERC20/base/ERC20BaseInternal.sol";
import {
    ERC20BaseStorage
} from "@solidstate/token/ERC20/base/ERC20BaseStorage.sol";
import {
    ERC20Extended
} from "@solidstate/token/ERC20/extended/ERC20Extended.sol";
import {
    ERC20Metadata
} from "@solidstate/token/ERC20/metadata/ERC20Metadata.sol";
import {
    ERC20MetadataInternal
} from "@solidstate/token/ERC20/metadata/ERC20MetadataInternal.sol";
import {
    ERC20Snapshot
} from "@solidstate/token/ERC20/snapshot/ERC20Snapshot.sol";
import {
    ERC20SnapshotInternal,
    ERC20SnapshotStorage
} from "@solidstate/token/ERC20/snapshot/ERC20SnapshotInternal.sol";
import { ERC20Permit } from "@solidstate/token/ERC20/permit/ERC20Permit.sol";
import {
    ERC20PermitInternal
} from "@solidstate/token/ERC20/permit/ERC20PermitInternal.sol";
import { Ownable } from "@solidstate/access/ownable/Ownable.sol";

// TODO: ? USDC Revocable Token Standard => would be cool
contract SupaERC20 is
    ERC20Base,
    ERC20Extended,
    ERC20Metadata,
    ERC20Permit,
    ERC20Snapshot,
    Ownable
{
    constructor(string memory name_, string memory symbol_, address owner_) {
        _setName(name_);
        _setSymbol(symbol_);
        _setOwner(owner_);
    }

    function currentSnapshot() public view returns (uint256 snapshotId) {
        snapshotId = ERC20SnapshotStorage.layout().snapshotId;
    }

    function incrementSnapshot() public returns (uint256 newSnapshotId) {
        newSnapshotId = ERC20SnapshotInternal._snapshot();
    }

    function mint(address receiver, uint256 amount) external onlyOwner {
        ERC20BaseStorage.layout().balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
    }

    function _setName(
        string memory newName
    ) internal virtual override(ERC20MetadataInternal, ERC20PermitInternal) {
        super._setName(newName);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20BaseInternal, ERC20SnapshotInternal) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
