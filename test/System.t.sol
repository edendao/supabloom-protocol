// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";

contract SystemTest is Test {
    function setUp() public {
        // Set up a schema for claims with EAS
        // Set up a schema for verifications with EAS
    }

    function testInvalidAttestationMint() public {
        // try attesting to an invalid claim
    }

    function testAttestationMint() public {
        // attest to a valid claim
        // verify that claim tokens were minted and transferred to msg.sender
    }

    function testAttestationAirdrop() public {
        // verify a claim by creating a referenced attestation
        // mint carbon credits and offer to holders of the claim tokens
        // verify that holders of the claim token have their pro-rata share of carbon credits
    }
}
