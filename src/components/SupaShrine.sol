// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.11;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "@solidstate/security/reentrancy_guard/ReentrancyGuard.sol";
import {SupaERC20} from "./SupaERC20.sol";

/// @title SupaShrine
/// @author zefram.eth, cyrusofeden.eth
/// A Champion can transfer their right to claim all future tokens offered to
/// the Champion to another address.
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

    event Offer(address indexed sender, SupaERC20 indexed source, address indexed token, uint256 amount);
    event Claim(
        address recipient,
        SupaERC20 indexed source,
        uint256 snapshotId,
        address indexed token,
        address indexed champion,
        uint256 claimedTokenAmount
    );
    event ClaimFromMetaShrine(SupaShrine indexed metaShrine);
    event TransferChampionStatus(address indexed champion, address recipient);

    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @param snapshotId Snapshot ID
    /// @param token The ERC-20 token to be claimed
    /// @param champion The Champion address. If the Champion rights
    ///                 have been transferred, the tokens will be sent to its owner.
    struct ClaimInfo {
        uint256 snapshotId;
        address token;
        address champion;
    }

    /// @param metaShrine The shrine to claim from
    /// @param snapshotId Snapshot ID
    /// @param token The ERC-20 token to be claimed
    struct MetaShrineClaimInfo {
        SupaShrine metaShrine;
        uint256 snapshotId;
        address token;
    }

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------
    mapping(
        SupaERC20 source
            => mapping(uint256 snapshotId => mapping(address token => mapping(address champion => uint256)))
    ) public claimedTokens;

    mapping(SupaERC20 source => mapping(uint256 snapshotId => mapping(address token => uint256))) public offeredTokens;

    mapping(address champion => address) public championClaimRightOwner;

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    constructor() {}

    // -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Offer ERC-20 tokens to the Shrine and distribute them to Champions proportional
    /// to their shares in the Shrine. Callable by anyone.
    /// @param source The SupaERC20 token holders to reward
    /// @param rewardToken The ERC-20 token being offered to the Shrine
    /// @param amount The amount of tokens to offer
    function offer(SupaERC20 source, address rewardToken, uint256 amount) external {
        // distribute tokens to Champions
        offeredTokens[source][source.incrementSnapshot()][rewardToken] += amount;
        // transfer tokens from sender
        SafeTransferLib.safeTransferFrom(rewardToken, msg.sender, address(this), amount);

        emit Offer(msg.sender, source, rewardToken, amount);
    }

    /// @notice A Champion or the owner of a Champion may call this to
    ///         claim their share of the tokens offered to this Shrine.
    /// Only callable by the champion (if the right was never transferred) or the owner
    /// (that the original champion transferred their rights to)
    /// @param claimInfo The info of the claim
    /// @return claimedTokenAmount The amount of tokens claimed
    function claim(address recipient, ClaimInfo calldata claimInfo) external returns (uint256 claimedTokenAmount) {
        // verify sender auth
        _verifyChampionOwnership(claimInfo.champion);

        // compute claimable amount
        uint256 championClaimedTokens = claimedTokens[claimInfo.snapshotId][claimInfo.token][claimInfo.champion];
        claimedTokenAmount = _computeClaimableTokenAmount(
            claimInfo.snapshotId, claimInfo.token, source.totalSupplyAt(claimInfo.snapshotId), championClaimedTokens
        );

        // record total tokens claimed by the champion
        claimedTokens[claimInfo.snapshotId][claimInfo.token][claimInfo.champion] =
            championClaimedTokens + claimedTokenAmount;

        // transfer tokens to the recipient
        SafeTransferLib.safeTransfer(claimInfo.token, recipient, claimedTokenAmount);

        emit Claim(recipient, claimInfo.snapshotId, claimInfo.token, claimInfo.champion, claimedTokenAmount);
    }

    /// @notice A variant of {claim} that combines multiple claims for the
    ///         same Champion & snapshotId into a single call.
    function claimMultipleTokensForChampion(
        address recipient,
        uint256 snapshot,
        address[] calldata tokenList,
        address champion,
        uint256 shares
    ) external returns (uint256[] memory claimedTokenAmountList) {
        // verify sender auth
        _verifyChampionOwnership(champion);

        claimedTokenAmountList = new uint256[](tokenList.length);
        for (uint256 i = 0; i < tokenList.length; i++) {
            // compute claimable amount
            uint256 championClaimedTokens = claimedTokens[snapshot][tokenList[i]][champion];
            claimedTokenAmountList[i] =
                _computeClaimableTokenAmount(snapshot, tokenList[i], shares, championClaimedTokens);

            // record total tokens claimed by the champion
            claimedTokens[snapshot][tokenList[i]][champion] = championClaimedTokens + claimedTokenAmountList[i];
        }

        for (uint256 i = 0; i < tokenList.length; i++) {
            // transfer tokens to the recipient
            SafeTransferLib.safeTransfer(tokenList[i], recipient, claimedTokenAmountList[i]);

            emit Claim(recipient, snapshot, tokenList[i], champion, claimedTokenAmountList[i]);
        }
    }

    /// @notice If this Shrine is a Champion of another Shrine (MetaShrine),
    ///         calling this can claim the tokens
    /// from the MetaShrine and distribute them to this Shrine's Champions. Callable by anyone.
    /// @param claimInfo The info of the claim
    /// @return claimedTokenAmount The amount of tokens claimed
    function claimFromMetaShrine(MetaShrineClaimInfo calldata claimInfo)
        external
        nonReentrant
        returns (uint256 claimedTokenAmount)
    {
        return _claimFromMetaShrine(claimInfo);
    }

    /// @notice A variant of {claimFromMetaShrine} that combines multiple claims into a single call.
    function claimMultipleFromMetaShrine(MetaShrineClaimInfo[] calldata claimInfoList)
        external
        nonReentrant
        returns (uint256[] memory claimedTokenAmountList)
    {
        // claim and distribute tokens
        claimedTokenAmountList = new uint256[](claimInfoList.length);
        for (uint256 i = 0; i < claimInfoList.length; i++) {
            claimedTokenAmountList[i] = _claimFromMetaShrine(claimInfoList[i]);
        }
    }

    /// @notice Allows a champion to transfer their right to claim from this shrine to
    /// another address. The champion will effectively lose their shrine membership, so
    /// make sure the new owner is a trusted party.
    /// Only callable by the champion (if the right was never transferred) or the owner
    /// (that the original champion transferred their rights to)
    /// @param champion The champion whose claim rights will be transferred away
    /// @param newOwner The address that will receive all rights of the champion
    function transferChampionClaimRight(address champion, address newOwner) external {
        // verify sender auth
        _verifyChampionOwnership(champion);

        championClaimRightOwner[champion] = newOwner;
        emit TransferChampionStatus(champion, newOwner);
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    /// @notice Computes the amount of a particular ERC-20 token claimable by a Champion from
    /// a particular snapshotId
    /// @param snapshot Snapshot ID
    /// @param token The ERC-20 token to be claimed
    /// @param champion The Champion address
    /// @param shares The share amount of the Champion
    /// @return claimableTokenAmount The amount of tokens claimable
    function computeClaimableTokenAmount(uint256 snapshot, address token, address champion, uint256 shares)
        public
        view
        returns (uint256 claimableTokenAmount)
    {
        claimableTokenAmount =
            _computeClaimableTokenAmount(snapshot, token, shares, claimedTokens[snapshot][token][champion]);
    }

    /// -----------------------------------------------------------------------
    /// Internal utilities
    /// -----------------------------------------------------------------------

    /// @dev Reverts if the sender isn't the champion or does not own the champion claim right
    /// @param champion The champion whose ownership will be verified
    function _verifyChampionOwnership(address champion) internal view {
        {
            address rightsOwner = championClaimRightOwner[champion];
            if (
                // claim right not transferred, sender should be the champion
                (rightsOwner == address(0) && msg.sender != champion)
                // claim right transferred, sender should be the owner
                || msg.sender != rightsOwner
            ) {
                revert NotAuthorized();
            }
        }
    }

    /// @dev See {computeClaimableTokenAmount}
    function _computeClaimableTokenAmount(uint256 snapshot, address token, uint256 shares, uint256 claimedTokenAmount)
        internal
        view
        returns (uint256 claimableTokenAmount)
    {
        uint256 totalShares = source.totalSupplyAt(snapshot);
        uint256 offeredTokenAmount = (offeredTokens[snapshot][token] * shares) / totalShares;

        // rounding may cause (offeredTokenAmount < claimedTokenAmount)
        // don't want to revert because of it
        claimableTokenAmount = offeredTokenAmount >= claimedTokenAmount ? offeredTokenAmount - claimedTokenAmount : 0;
    }

    /// @dev See {claimFromMetaShrine}
    function _claimFromMetaShrine(MetaShrineClaimInfo calldata claimInfo)
        internal
        returns (uint256 claimedTokenAmount)
    {
        // claim tokens from the meta shrine
        IERC20 token = IERC20(claimInfo.token);
        uint256 beforeBalance = token.balanceOf(address(this));
        claimInfo.metaShrine.claim(
            address(this),
            ClaimInfo({snapshotId: claimInfo.snapshotId, token: claimInfo.token, champion: address(this)})
        );
        claimedTokenAmount = token.balanceOf(address(this)) - beforeBalance;

        // distribute tokens to Champions
        offeredTokens[snapshotId][claimInfo.token] += claimedTokenAmount;

        emit Offer(address(claimInfo.metaShrine), claimInfo.token, claimedTokenAmount);
        emit ClaimFromMetaShrine(claimInfo.metaShrine);
    }
}
