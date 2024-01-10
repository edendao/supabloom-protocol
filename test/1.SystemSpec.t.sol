// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {TestSystem} from "./mixins/TestSystem.sol";

contract SystemSpecTest is TestSystem {
    function setUp() public {
        // Set up a schema for claims with EAS
        // register the schema with our controller with a token name and symbol
        //    this deploys the token but does not mint
        //    use OwnableRoles

        // Set up a schema for validations with EAS
        // register the schema with our controller with a token name and symbol
        //    this deploys the token but does not mint
    }

    function testClaiming() public {
        // create a claim attestation with EAS
        // claim should use the claim schema and the uint256 field is the amount of the token to mint
        // call our controller contract with the claimAttestationID and a receiver address
        //      our controller contract verifies that the claim is not revocable
        // assert that this deployed a SupaERC20 and minted `amount` tokens to the receiver
    }

    function testClaimingIdempotency() public {
        // call `testClaims()` a few times and verify that only a single ERC20 was deployed,
        // and mint only happened once
    }

    function testRewarding() public {
        // PART 1 — CLAIMING ==================
        // create a claim attestation with EAS
        // controller.claim(claimAttestationID, address receiver)
        //    this mints claim ERC20s to the receiver address, for this test, use address(this) (this test contract)
        // distribute some claim ERC20s to 3 addresses

        // PART 2 — Rewarding ==============
        // create a "reward attestation" on EAS => this is an attestation with refUID = claimAttestationID
        // controller.reward(rewardAttestationID, uint256 rewardAmount)
        //    this mints credit `rewardAmount` ERC20s, and calls SupaShrine.reward(claimERC20Token, creditERC20Token, rewardAmount)

        // assert that a new snapshot was taken of the claimToken ERC20
        // assert that the various holders of the claimToken ERC20s can claim their pro-rata reward

        // prank the holders and claim the reward tokens
        // assert they got what they should have got
    }

    function testRewardingIdempotency() public {
        // verify that claimToken holders cannot claim from the shrine more than once
    }

    function testRewardingAcrossSnapshots() public {
        // this is the same as testRewarding() but move tokens around and take a few snapshots between Part 1 and Part 2 and verify that it all works
    }
}
