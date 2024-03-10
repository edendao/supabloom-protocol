//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

interface ISupaShrine {
    struct ClaimInfo {
        uint256 snapshotId;
        address claimToken;
        address rewardToken;
        address receiver;
    }

    function reward(address claimToken, address rewardToken, uint256 rewardAmount) external;

    function claim(address recipient, ClaimInfo calldata claimInfo)
        external
        returns (uint256 claimedRewardTokenAmount);

    function claimableTokenAmount(ClaimInfo calldata claimInfo, uint256 shares)
        external
        view
        returns (uint256 claimableTokenAmount);
}
