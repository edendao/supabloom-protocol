// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {TestSystem} from "./mixins/TestSystem.sol";

contract SystemSpecTest is TestSystem {
    function setUp() public {
        // Set up a schema for claims with EAS through our controller
        // The first 2 fields of the schema should be the token name, symbol

        // Set up a schema for validations with EAS through our controller
        // The first 2 fields of the schema should be the token name, and symbol
    }

    function testClaiming() public {
        // create a claim attestation with EAS through our controller
        // claim should use the claim schema and the first field should be the uint256 totalSupply
        // verify that claim is not revocable
        // call our controller contract with the claimAttestationID and a receiver address
        // verify that this deployed a SupaERC20 and minted `totalSupply` tokens to the receiver
    }

    function testClaimingIdempotency() public {
        // call `testClaims()` a few times and verify that only a single ERC20 was deployed
    }

    function testAccrediting() public {
        // create a claim attestation with EAS with the receiver set to this contract
        // distribute some claim ERC20s to some addresses

        // use the controller to create a validation attestation
        // verify that the attestation is revocable
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the various holders of the claim ERC20s can claim their pro-rata reward
    }

    function testAccreditingIdempotency() public {
        // call `testValidations()` a few times and verify that only a single 'CreditERC20' was deployed
    }

    function testAccreditingAcrossSnapshots() public {
        // create a claim attestation with EAS with the receiver set to this contract
        // use the controller to create a validation attestation
        // verify that the attestation is revocable
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20

        // move some tokens around
        // manually update the snapshot on the ERC20

        // use the controller to create a validation attestation
        // verify that the attestation is revocable
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
    }

    function testRevokingAccreditation() public {
        // create a claim attestation with EAS with the receiver set to this contract
        // distribute the claim ERC20s to a total of 3 addresses

        // use the controller to create a validation attestation
        // verify that the attestation is revocable
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the various holders of the claim ERC20s can claim their pro-rata reward
        // claim the reward for 2/3 of the holders

        // revoke the validation attestation through our controller
        // verify that 2/3 credit ERC20 holders no longer hold any tokens
        // verify that the remaining 1/3 credit ERC20 holder cannot claim any reward
    }
}
