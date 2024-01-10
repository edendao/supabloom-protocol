// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {TestSystem} from "./mixins/TestSystem.sol";

contract ImpactTranchesTest is TestSystem {
    function setUp() public {
        // Set up 3 schemas for claims with EAS
        // The first 2 fields of the schema should be the token name, symbol

        // Set up a 'carbon credit' schema for validations with EAS
        // The first 2 fields of the schema should be the token name, and symbol
    }

    function testClaimingTranches() public {
        // create 3 claims attestation with EAS, with different tranches in their name (e.g. "AAA", "AA", "A")
        // claim should use the claim schema and the first field should be the uint256 totalSupply
        // call our controller contract with the claimAttestationID and a receiver address
        // verify that this deployed a SupaERC20 and minted `totalSupply` tokens to the receiver
    }

    function testRewardingTranches() public {
        // create a claim attestation for tranches AAA with EAS with the receiver set to this contract
        // create a claim attestation for tranches AA with EAS with the receiver set to this contract
        // create a claim attestation for tranches A with EAS with the receiver set to this contract
        // distribute to 3 addresses
        // warp time to the future

        // create a validation attestation for 'carbon credit' referencing claim for tranches AAA with the first field as uint256 reward
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the current holders of the claim ERC20s can claim their pro-rata reward

        // create a validation attestation for 'carbon credit' referencing claim for tranches AA with the first field as uint256 reward
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the current holders of the claim ERC20s can claim their pro-rata reward

        // create a validation attestation for 'carbon credit' referencing claim for tranches A with the first field as uint256 reward
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the current holders of the claim ERC20s can claim their pro-rata reward
    }
}
