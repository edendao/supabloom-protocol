// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {TestSystem} from "./mixins/TestSystem.sol";

contract MultiDimensionalImpactCreditsTest is TestSystem {
    function setUp() public {
        // Set up a schema for claims with EAS
        // The first 2 fields of the schema should be the token name, symbol

        // Set up a 'carbon credit' schema for validations with EAS
        // The first 2 fields of the schema should be the token name, and symbol

        // Set up a 'biodiversity credit' schema for validations with EAS
        // The first 2 fields of the schema should be the token name, and symbol
    }

    function testClaimingFutureImpact() public {
        // create a claim attestation with EAS
        // claim should use the claim schema and the first field should be the uint256 totalSupply
        // call our controller contract with the claimAttestationID and a receiver address
        // verify that this deployed a SupaERC20 and minted `totalSupply` tokens to the receiver
    }

    function testAccreditingImpact() public {
        // create a claim attestation with EAS with the receiver set to this contract
        // warp the timestamp forward to the future

        // create a validation attestation for 'carbon credit' with the first field as uint256 reward
        // call our controller contract with the validationAttestationID
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the current holders of the claim ERC20s can claim their pro-rata reward

        // distribute some of the Claim ERC20s to some addresses
        // create a validation attestation for 'biodiversity credit' with the first field as uint256 reward
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the current holders of the claim ERC20s can claim their pro-rata reward
    }
}
