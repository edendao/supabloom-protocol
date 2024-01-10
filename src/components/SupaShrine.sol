// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.11;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import {
    ReentrancyGuard
} from "@solidstate/security/reentrancy_guard/ReentrancyGuard.sol";
import { SupaERC20 } from "./SupaERC20.sol";

/// @title SupaShrine
/// @author zefram.eth, cyrusofeden.eth, tabish.eth
/// A Receiver can transfer their right to claim all future tokens offered to
/// the Receiver to another address.
contract SupaShrine is ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error NotAuthorized();

    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Offer(
        address indexed sender,
        address indexed claimToken,
        address indexed token,
        uint256 amount
    );
    event Claim(
        address recipient,
        address indexed claimToken,
        uint256 snapshotId,
        address indexed token,
        address indexed receiver,
        uint256 claimedTokenAmount
    );
    event TransferReceiverStatus(address indexed receiver, address recipient);

    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @param snapshotId Snapshot ID
    /// @param token The ERC-20 token to be claimed
    /// @param receiver The Receiver address. If the Receiver rights
    ///                 have been transferred, the tokens will be sent to its owner.
    struct ClaimInfo {
        uint256 snapshotId;
        address claimToken;
        address rewardToken;
        address receiver;
    }

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------
    mapping(address claimToken => mapping(uint256 snapshotId => mapping(address rewardToken => uint256)))
        public rewardedTokens;

    mapping(address claimToken => mapping(uint256 snapshotId => mapping(address rewardToken => mapping(address receiver => uint256))))
        public claimedRewardTokens;

    mapping(address receiver => address) public receiverClaimRightOwner;

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    constructor() {}

    // -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Offer ERC-20 tokens to the Shrine and distribute them to Receivers proportional
    /// to their shares in the Shrine. Callable by anyone.
    /// @param claimToken The SupaERC20 token holders to reward
    /// @param rewardToken The ERC-20 token being offered to the Shrine
    /// @param rewardAmount The amount of tokens to offer
    function reward(
        address claimToken,
        address rewardToken,
        uint256 rewardAmount
    ) external {
        // distribute tokens to Receivers
        rewardedTokens[claimToken][SupaERC20(claimToken).incrementSnapshot()][
            rewardToken
        ] += rewardAmount;
        // transfer tokens from sender
        SafeTransferLib.safeTransferFrom(
            rewardToken,
            msg.sender,
            address(this),
            rewardAmount
        );

        emit Offer(msg.sender, claimToken, rewardToken, rewardAmount);
    }

    /// @notice A Receiver or the owner of a Receiver may call this to
    ///         claim their share of the tokens offered to this Shrine.
    /// Only callable by the receiver (if the right was never transferred) or the owner
    /// (that the original receiver transferred their rights to)
    /// @param claimInfo The info of the claim
    /// @return claimedTokenAmount The amount of tokens claimed
    function claim(
        address recipient,
        ClaimInfo calldata claimInfo
    ) public returns (uint256 claimedTokenAmount) {
        // verify sender auth
        _verifyReceiverOwnership(claimInfo.receiver);

        // compute claimable amount
        uint256 receiverClaimedRewardTokens = claimedRewardTokens[
            claimInfo.claimToken
        ][claimInfo.snapshotId][claimInfo.rewardToken][claimInfo.receiver];
        claimedTokenAmount = _computeClaimableTokenAmount(
            claimInfo.snapshotId,
            claimInfo.claimToken,
            claimInfo.rewardToken,
            SupaERC20(claimInfo.claimToken).balanceOfAt(
                claimInfo.receiver,
                claimInfo.snapshotId
            ),
            receiverClaimedRewardTokens
        );

        // record total tokens claimed by the receiver
        claimedRewardTokens[claimInfo.claimToken][claimInfo.snapshotId][
            claimInfo.rewardToken
        ][claimInfo.receiver] =
            receiverClaimedRewardTokens +
            claimedTokenAmount;

        // transfer tokens to the recipient
        SafeTransferLib.safeTransfer(
            claimInfo.rewardToken,
            recipient,
            claimedTokenAmount
        );

        emit Claim(
            recipient,
            claimInfo.claimToken,
            claimInfo.snapshotId,
            claimInfo.rewardToken,
            claimInfo.receiver,
            claimedTokenAmount
        );
    }

    /// @notice A variant of {claim} that combines multiple claims for the
    ///         same Receiver & snapshotId into a single call.
    function claimMultipleTokensForReceiver(
        address recipient,
        ClaimInfo[] calldata claimInfo
    ) external returns (uint256[] memory claimedTokenAmountList) {
        claimedTokenAmountList = new uint256[](claimInfo.length);
        for (uint256 i = 0; i < claimInfo.length; i++) {
            // verify sender auth
            _verifyReceiverOwnership(claimInfo[i].receiver);

            // compute claimable amount and send tokens
            claimedTokenAmountList[i] = claim(recipient, claimInfo[i]);
        }
    }

    /// @notice Allows a receiver to transfer their right to claim from this shrine to
    /// another address. The receiver will effectively lose their shrine membership, so
    /// make sure the new owner is a trusted party.
    /// Only callable by the receiver (if the right was never transferred) or the owner
    /// (that the original receiver transferred their rights to)
    /// @param receiver The receiver whose claim rights will be transferred away
    /// @param newOwner The address that will receive all rights of the receiver
    function transferReceiverClaimRight(
        address receiver,
        address newOwner
    ) external {
        // verify sender auth
        _verifyReceiverOwnership(receiver);

        receiverClaimRightOwner[receiver] = newOwner;
        emit TransferReceiverStatus(receiver, newOwner);
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    /// @notice Computes the amount of a particular ERC-20 token claimable by a Receiver from
    /// a particular snapshotId
    /// @param snapshot Snapshot ID
    /// @param claimToken The reward ERC-20 token to be claimed
    /// @param receiver The Receiver address
    /// @param shares The share amount of the Receiver
    /// @return claimableTokenAmount The amount of tokens claimable
    function computeClaimableTokenAmount(
        uint256 snapshot,
        address claimToken,
        address rewardToken,
        address receiver,
        uint256 shares
    ) public view returns (uint256 claimableTokenAmount) {
        claimableTokenAmount = _computeClaimableTokenAmount(
            snapshot,
            claimToken,
            rewardToken,
            shares,
            claimedRewardTokens[claimToken][snapshot][rewardToken][receiver]
        );
    }

    /// -----------------------------------------------------------------------
    /// Internal utilities
    /// -----------------------------------------------------------------------

    /// @dev Reverts if the sender isn't the receiver or does not own the receiver claim right
    /// @param receiver The receiver whose ownership will be verified
    function _verifyReceiverOwnership(address receiver) internal view {
        {
            address rightsOwner = receiverClaimRightOwner[receiver];
            if (
                // claim right not transferred, sender should be the receiver
                (rightsOwner == address(0) && msg.sender != receiver) ||
                // claim right transferred, sender should be the owner
                msg.sender != rightsOwner
            ) {
                revert NotAuthorized();
            }
        }
    }

    /// @dev See {computeClaimableTokenAmount}
    function _computeClaimableTokenAmount(
        uint256 snapshot,
        address claimToken,
        address rewardToken,
        uint256 shares,
        uint256 claimedTokenAmount
    ) internal view returns (uint256 claimableTokenAmount) {
        uint256 totalShares = SupaERC20(claimToken).totalSupplyAt(snapshot);
        uint256 offeredTokenAmount = (rewardedTokens[claimToken][snapshot][
            rewardToken
        ] * shares) / totalShares;

        // rounding may cause (offeredTokenAmount < claimedTokenAmount)
        // don't want to revert because of it
        claimableTokenAmount = offeredTokenAmount >= claimedTokenAmount
            ? offeredTokenAmount - claimedTokenAmount
            : 0;
    }
}
