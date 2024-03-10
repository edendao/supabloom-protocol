// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {SupaShrine} from "../src/components/SupaShrine.sol";
import {SupaERC20} from "../src/components/SupaERC20.sol";

contract SupaShrineTest is Test {
    SupaShrine supaShrine;
    SupaERC20 claimToken;
    SupaERC20 rewardToken;

    function setUp() public {
        // Deploy SupaShrine
        supaShrine = new SupaShrine();

        // Deploy SupaERC20
        claimToken = new SupaERC20("ClaimToken", "CLAIM", address(this), address(this));
        // Deploy SupaERC20
        rewardToken = new SupaERC20("RewardToken", "REWARD", address(this), address(this));
    }

    function testOffering() public {
        // Mint Claim tokens and reward tokens
        claimToken.mint(address(this), 1000 ether);
        rewardToken.mint(address(this), 1 ether);

        // Approve SupaShrine
        rewardToken.approve(address(supaShrine), 1 ether);
        supaShrine.reward(address(claimToken), address(rewardToken), 1 ether);

        // check if snapshot incremented
        assertEq(claimToken.currentSnapshot(), 1);

        // check if reward token balance is 0
        assertEq(rewardToken.balanceOf(address(this)), 0);
        // check if reward token balance of supashrine is 1
        assertEq(rewardToken.balanceOf(address(supaShrine)), 1 ether);
    }

    function testClaiming() public {
        // Mint Claim tokens and reward tokens
        claimToken.mint(address(this), 1000 ether);
        rewardToken.mint(address(this), 1 ether);

        // Approve SupaShrine
        rewardToken.approve(address(supaShrine), 1 ether);
        supaShrine.reward(address(claimToken), address(rewardToken), 1 ether);

        // check if reward token balance is 0
        assertEq(rewardToken.balanceOf(address(this)), 0);

        // claim reward
        SupaShrine.ClaimInfo memory claimInfo =
            SupaShrine.ClaimInfo(1, address(claimToken), address(rewardToken), address(this));

        supaShrine.claim(address(this), claimInfo);

        // check if reward token balance is 1 ether
        assertEq(rewardToken.balanceOf(address(this)), 1 ether);
    }
}
