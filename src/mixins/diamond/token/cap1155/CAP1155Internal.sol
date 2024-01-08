// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { SafeCastLib } from "solady/utils/SafeCastLib.sol";

import {
    IERC1155Receiver
} from "@solidstate/contracts/interfaces/IERC1155Receiver.sol";
import {
    IERC1155BaseInternal
} from "@solidstate/contracts/token/ERC1155/base/IERC1155BaseInternal.sol";

import { CAP1155Storage, BalanceMap } from "./CAP1155Storage.sol";

abstract contract CAP1155Internal is IERC1155BaseInternal {
    using BalanceMap for BalanceMap.Map;
    using SafeCastLib for uint256;

    error CAP1155__NonTransferrable(uint256 id);

    function _isTransferrable(uint256 id) internal pure virtual returns (bool);

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(
        address account,
        uint256 id
    ) internal view returns (uint256) {
        return CAP1155Storage.layout().balances[id].get(account);
    }

    /**
     * @notice query the total supply of given token
     * @param id token to query
     * @return token total supply
     */
    function _totalSupply(uint256 id) internal view returns (uint256) {
        return CAP1155Storage.layout().totalSupply[id];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory
    ) internal virtual {
        if (account == address(0)) {
            revert ERC1155Base__MintToZeroAddress();
        }

        CAP1155Storage.Layout storage l = CAP1155Storage.layout();
        uint64 amountU64 = amount.toUint64();
        l.balances[id].add(account, amountU64);
        l.totalSupply[id] += amountU64;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual {
        if (account == address(0)) {
            revert ERC1155Base__MintToZeroAddress();
        }
        if (ids.length != amounts.length) {
            revert ERC1155Base__ArrayLengthMismatch();
        }

        CAP1155Storage.Layout storage l = CAP1155Storage.layout();
        mapping(uint256 => BalanceMap.Map) storage balances = l.balances;
        mapping(uint256 => uint64) storage supplies = l.totalSupply;

        unchecked {
            uint256 id;
            uint64 amount;
            for (uint256 i = ids.length; i-- != 0; ) {
                id = ids[i];
                amount = amounts[i].toUint64();
                balances[id].add(account, amount);
                supplies[id] += amount;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        CAP1155Storage.Layout storage l = CAP1155Storage.layout();

        l.totalSupply[uint256(id)] += uint64(amount);
        l.balances[uint256(id)].subtract(account, uint64(amount));

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (ids.length != amounts.length) {
            revert ERC1155Base__ArrayLengthMismatch();
        }

        CAP1155Storage.Layout storage l = CAP1155Storage.layout();
        mapping(uint256 => BalanceMap.Map) storage balances = l.balances;
        mapping(uint256 => uint64) storage supplies = l.totalSupply;

        unchecked {
            uint256 id;
            uint64 amount;
            for (uint256 i = ids.length; i-- != 0; ) {
                id = ids[i];
                amount = amounts[i].toUint64();

                supplies[id] -= amount;
                balances[id].subtract(account, amount);
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory
    ) internal virtual {
        if (recipient == address(0)) {
            revert ERC1155Base__TransferToZeroAddress();
        }
        if (!_isTransferrable(id)) {
            revert CAP1155__NonTransferrable(id);
        }

        BalanceMap.Map storage balances = CAP1155Storage.layout().balances[
            uint256(id)
        ];
        balances.subtract(sender, uint64(amount));
        balances.add(recipient, uint64(amount));

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual {
        if (ids.length != amounts.length) {
            revert ERC1155Base__ArrayLengthMismatch();
        }

        mapping(uint256 => BalanceMap.Map) storage balances = CAP1155Storage
            .layout()
            .balances;

        unchecked {
            uint256 id;
            uint64 amount;
            for (uint256 i = ids.length; i-- != 0; ) {
                id = ids[i];
                if (!_isTransferrable(id)) {
                    revert CAP1155__NonTransferrable(id);
                }

                // Update balances
                amount = uint64(amounts[i]);
                BalanceMap.Map storage b = balances[id];

                b.subtract(sender, amount);
                b.add(recipient, amount);
            }
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length != 0) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155Base__ERC1155ReceiverRejected();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length != 0) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert ERC1155Base__ERC1155ReceiverRejected();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    function _expandTokenBalances(
        uint256 id,
        uint64 numerator,
        uint64 denominator
    ) internal {
        CAP1155Storage.Layout storage l = CAP1155Storage.layout();
        BalanceMap.Entry[] storage entries = l.balances[uint256(id)].entries;

        uint64 minted;
        unchecked {
            BalanceMap.Entry storage entry;
            uint64 x;
            for (uint256 i = entries.length; i-- != 0; ) {
                entry = entries[i];
                x = entry.value;
                x = (entry.value = (x * numerator) / denominator) - x;

                minted += x;
                emit TransferSingle(
                    address(this),
                    address(0),
                    entry.key,
                    id,
                    x
                );
            }
        }

        l.totalSupply[uint256(id)] += minted;
    }

    function _contractTokenBalances(
        uint256 id,
        uint64 numerator,
        uint64 denominator
    ) internal {
        CAP1155Storage.Layout storage l = CAP1155Storage.layout();
        BalanceMap.Entry[] storage entries = l.balances[uint256(id)].entries;

        uint64 burned;
        unchecked {
            BalanceMap.Entry storage entry;
            uint64 x;
            for (uint256 i = entries.length; i-- != 0; ) {
                entry = entries[i];
                x = entry.value;
                x = x - (entry.value = (x * numerator) / denominator);

                burned += x;
                emit TransferSingle(
                    address(this),
                    entry.key,
                    address(0),
                    id,
                    x
                );
            }
        }

        l.totalSupply[uint256(id)] -= burned;
    }

    function _clearTokenBalances(uint256 id) internal {
        CAP1155Storage.Layout storage l = CAP1155Storage.layout();
        BalanceMap.Map storage balances = l.balances[uint256(id)];
        BalanceMap.Entry[] storage entries = balances.entries;

        unchecked {
            BalanceMap.Entry storage entry;
            uint64 x;
            for (uint256 i = entries.length; i-- != 0; ) {
                entry = entries[i];
                x = entry.value;
                balances.remove(entry.key);

                emit TransferSingle(
                    address(this),
                    entry.key,
                    address(0),
                    id,
                    x
                );
            }
        }

        l.totalSupply[uint256(id)] = 0;
    }
}
