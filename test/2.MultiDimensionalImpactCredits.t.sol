// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {TestSystem} from "./mixins/TestSystem.sol";
import {ISchemaRegistry} from "@eas/ISchemaRegistry.sol";
import {ISchemaResolver} from "@eas/resolver/ISchemaResolver.sol";
import {IEAS, AttestationRequest, AttestationRequestData} from "@eas/IEAS.sol";
import {NO_EXPIRATION_TIME, EMPTY_UID} from "@eas/Common.sol";
import {SupaController} from "../src/components/SupaController.sol";
import {SupaShrine} from "~/components/SupaShrine.sol";
import {ISupaERC20} from "../src/components/interfaces/ISupaERC20.sol";

contract MultiDimensionalImpactCreditsTest is TestSystem {
    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    ISchemaRegistry schemaRegistry = ISchemaRegistry(0xA7b39296258348C78294F95B872b282326A97BDF); // Mainnet Schema Registry
    IEAS eas = IEAS(0xA1207F3BBa224E2c9c3c6D5aF63D0eb1582Ce587); // Mainnet EAS
    SupaController controller;
    SupaShrine supaShrine;

    bytes32 claimSchemaUID;
    address claimToken;
    bytes32 carbonCreditSchemaUID;
    address rewardToken1;
    bytes32 biodiversitySchemaUID;
    address rewardToken2;

    function setUp() public {
        // Set up a fork of mainnet
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        // Deploy SupaShrine
        supaShrine = new SupaShrine();

        // Deploy SupaController
        controller = new SupaController(eas, address(supaShrine), address(schemaRegistry));

        // Set up a schema for claims with EAS
        // The first 2 fields of the schema should be the token name, symbol
        (claimSchemaUID, claimToken) =
            controller.registerSchema("uint256 claimTokenAmount, string data", "Token1", "T1");

        // Set up a 'carbon credit' schema for validations with EAS
        // The first 2 fields of the schema should be the token name, and symbol
        (carbonCreditSchemaUID, rewardToken1) =
            controller.registerSchema("uint256 rewardTokenAmount, string data", "Reward Token", "RT");

        // Set up a 'biodiversity credit' schema for validations with EAS
        // The first 2 fields of the schema should be the token name, and symbol
        (biodiversitySchemaUID, rewardToken2) =
            controller.registerSchema("uint256 rewardTokenAmount1, string data1", "Reward Token 1", "RT1");
    }

    function testClaimingFutureImpact() public {
        // create a claim attestation with EAS
        // claim should use the claim schema and the first field should be the uint256 totalSupply
        // call our controller contract with the claimAttestationID and a receiver address
        // verify that this deployed a SupaERC20 and minted `totalSupply` tokens to the receiver

        uint256 amount = 10 ether;
        string memory data = "data";
        bytes32 claimAttestationUID1 = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: EMPTY_UID, // No references UI
                    data: abi.encode(amount, data), // Encode a single uint256 as a parameter to the schema
                    value: 0 // No value/ETH
                })
            })
        );

        // call our controller contract with the claimAttestationID and a receiver address
        // verify that this deployed a SupaERC20 and minted `totalSupply` tokens to the receiver
        controller.claim(claimAttestationUID1, address(this));
        assert(ISupaERC20(claimToken).balanceOf(address(this)) == 10 ether);
    }

    function testRewardingImpact() public {
        // create a claim attestation with EAS with the receiver set to this contract
        // warp the timestamp forward to the future

        uint256 amount = 12 ether;
        string memory data = "claim";
        bytes32 claimAttestationUID1 = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: EMPTY_UID, // No references UI
                    data: abi.encode(amount, data), // Encode a single uint256 as a parameter to the schema
                    value: 0 // No value/ETH
                })
            })
        );

        controller.claim(claimAttestationUID1, address(this));
        vm.warp(1000);

        // create a validation attestation for 'carbon credit' with the first field as uint256 reward
        // call our controller contract with the validationAttestationID
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the current holders of the claim ERC20s can claim their pro-rata reward
        amount = 21 ether;
        data = "Carbon Credit";
        bytes32 rewardAttestationID1 = eas.attest(
            AttestationRequest({
                schema: carbonCreditSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: claimAttestationUID1, // No references UI
                    data: abi.encode(amount, data), // Encode a single uint256 as a parameter to the schema
                    value: 0 // No value/ETH
                })
            })
        );

        // Snapshot number before calling reward function
        uint256 snapshotId = ISupaERC20(claimToken).currentSnapshot();

        // this mints credit `rewardAmount` ERC20s, and calls SupaShrine.reward(claimERC20Token, creditERC20Token, rewardAmount)
        controller.reward(rewardAttestationID1, address(controller));
        // assert that a new snapshot was taken of the claimToken ERC20
        // Snapshot number before calling reward function
        uint256 newSnapshotId = ISupaERC20(claimToken).currentSnapshot();
        assert(newSnapshotId == snapshotId + 1);
        // assert that the various holders of the claimToken ERC20s can claim their pro-rata reward
        SupaShrine.ClaimInfo memory claimInfo =
            SupaShrine.ClaimInfo(newSnapshotId, claimToken, rewardToken1, address(this));
        supaShrine.claim(address(this), claimInfo);
        // assert they got what they should have got
        assert(ISupaERC20(rewardToken1).balanceOf(address(this)) == 21 ether);

        // distribute some of the Claim ERC20s to some addresses
        address user1 = makeAddr("user1");
        ISupaERC20(claimToken).transfer(user1, 6 ether);
        // create a validation attestation for 'biodiversity credit' with the first field as uint256 reward
        amount = 10 ether;
        data = "BioDiversity Credit";
        bytes32 rewardAttestationID2 = eas.attest(
            AttestationRequest({
                schema: biodiversitySchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: claimAttestationUID1, // No references UI
                    data: abi.encode(amount, data), // Encode a single uint256 as a parameter to the schema
                    value: 0 // No value/ETH
                })
            })
        );
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        snapshotId = ISupaERC20(claimToken).currentSnapshot();
        controller.reward(rewardAttestationID2, address(controller));
        newSnapshotId = ISupaERC20(claimToken).currentSnapshot();
        claimInfo = SupaShrine.ClaimInfo(newSnapshotId, claimToken, rewardToken2, user1);
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the current holders of the claim ERC20s can claim their pro-rata reward
        vm.prank(user1);
        supaShrine.claim(user1, claimInfo);
        // assert they got what they should have got
        assert(ISupaERC20(rewardToken2).balanceOf(user1) == 5 ether);
    }
}
