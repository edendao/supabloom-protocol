// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {TestSystem} from "./mixins/TestSystem.sol";
import { ISchemaRegistry } from "@eas/ISchemaRegistry.sol";
import { ISchemaResolver } from "@eas/resolver/ISchemaResolver.sol";
import {
    IEAS,
    AttestationRequest,
    AttestationRequestData
} from "@eas/IEAS.sol";
import { NO_EXPIRATION_TIME, EMPTY_UID } from "@eas/Common.sol";
import { SupaController } from "../src/components/SupaController.sol";
import { SupaShrine } from "~/components/SupaShrine.sol";
import { ISupaERC20 } from "../src/components/interfaces/ISupaERC20.sol";

contract ImpactTranchesTest is TestSystem {

    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");


    ISchemaRegistry schemaRegistry = ISchemaRegistry(0xA7b39296258348C78294F95B872b282326A97BDF); // Mainnet Schema Registry
    IEAS eas = IEAS(0xA1207F3BBa224E2c9c3c6D5aF63D0eb1582Ce587); // Mainnet EAS
    SupaController controller;
    SupaShrine supaShrine;

    bytes32 claimSchemaUID1;
    bytes32 claimSchemaUID2;
    bytes32 claimSchemaUID3;
    address claimToken1;
    address claimToken2;
    address claimToken3;

    bytes32 validationSchemaUID;
    address rewardToken;

    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        // Set up 3 schemas for claims with EAS
        // The first 2 fields of the schema should be the token name, symbol

        // Deploy SupaShrine
        supaShrine = new SupaShrine();

        // Deploy SupaController
        controller = new SupaController(eas, address(supaShrine), address(schemaRegistry));

        (claimSchemaUID1, claimToken1) = controller.registerSchema(
            "uint256 claimTokenAmount, string data",
            "Token1",
            "T1"
        );

        (claimSchemaUID2, claimToken2) = controller.registerSchema(
            "uint256 claimTokenAmount1, string data1",
            "Token2",
            "T2"
        );

        (claimSchemaUID3, claimToken3) = controller.registerSchema(
            "uint256 claimTokenAmount2, string data2",
            "Token3",
            "T3"
        );


        // Set up a 'carbon credit' schema for validations with EAS
        // The first 2 fields of the schema should be the token name, and symbol

        (validationSchemaUID, rewardToken) = controller.registerSchema(
            "uint256 rewardTokenAmount, string data",
            "Reward Token",
            "RT"
        );
    }

    function testClaimingTranches() public {
        // create 3 claims attestation with EAS, with different tranches in their name (e.g. "AAA", "AA", "A")
        // claim should use the claim schema and the first field should be the uint256 totalSupply

        // create a claim attestation with EAS
        uint256 amount = 10 ether;
        string memory data = "AAA";
        bytes32 claimAttestationUID1 = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID1,
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

        amount = 20 ether;
        data = "AA";

        bytes32 claimAttestationUID2 = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID2,
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

        amount = 30 ether;
        data = "A";

        bytes32 claimAttestationUID3 = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID3,
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
        assert(ISupaERC20(claimToken1).balanceOf(address(this)) == 10 ether);

        controller.claim(claimAttestationUID2, address(this));
        assert(ISupaERC20(claimToken2).balanceOf(address(this)) == 20 ether);

        controller.claim(claimAttestationUID3, address(this));
        assert(ISupaERC20(claimToken3).balanceOf(address(this)) == 30 ether);
    }

    function testRewardingTranches() public {
        // create a claim attestation for tranches AAA with EAS with the receiver set to this contract
        // create a claim attestation for tranches AA with EAS with the receiver set to this contract
        // create a claim attestation for tranches A with EAS with the receiver set to this contract
        
        uint256 amount = 12 ether;
        string memory data = "AAA";
        bytes32 claimAttestationUID1 = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID1,
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

        data = "AA";
        bytes32 claimAttestationUID2 = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID2,
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

        data = "A";
        bytes32 claimAttestationUID3 = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID3,
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
        controller.claim(claimAttestationUID2, address(this));
        controller.claim(claimAttestationUID3, address(this));

        // distribute to 3 addresses
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        ISupaERC20(claimToken1).transfer(user1, 4 ether);
        ISupaERC20(claimToken1).transfer(user2, 4 ether);
        ISupaERC20(claimToken1).transfer(user3, 4 ether);
        ISupaERC20(claimToken2).transfer(user1, 4 ether);
        ISupaERC20(claimToken2).transfer(user2, 4 ether);
        ISupaERC20(claimToken2).transfer(user3, 4 ether);
        ISupaERC20(claimToken3).transfer(user1, 4 ether);
        ISupaERC20(claimToken3).transfer(user2, 4 ether);
        ISupaERC20(claimToken3).transfer(user3, 4 ether);
        // warp time to the future
        vm.warp(60);

        // create a validation attestation for 'carbon credit' referencing claim for tranches AAA with the first field as uint256 reward
        // verify that this deployed a SupaERC20 and offered `reward` to the current snapshot of the claim's ERC20
        // verify that a new snapshot was taken of the claim's ERC20
        // verify that the current holders of the claim ERC20s can claim their pro-rata reward
        amount = 21 ether;
        data = "AAA";
        bytes32 rewardAttestationID1 = eas.attest(
            AttestationRequest({
                schema: validationSchemaUID,
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
        uint256 snapshotId = ISupaERC20(claimToken1).currentSnapshot();

        // this mints credit `rewardAmount` ERC20s, and calls SupaShrine.reward(claimERC20Token, creditERC20Token, rewardAmount)
        controller.reward(rewardAttestationID1, address(controller));
        // assert that a new snapshot was taken of the claimToken ERC20
        // Snapshot number before calling reward function
        uint256 newSnapshotId = ISupaERC20(claimToken1).currentSnapshot();
        assert(newSnapshotId == snapshotId + 1);
        // assert that the various holders of the claimToken ERC20s can claim their pro-rata reward
        SupaShrine.ClaimInfo memory claimInfo = SupaShrine.ClaimInfo(
            newSnapshotId,
            claimToken1,
            rewardToken,
            user1
        );
        // prank the holders and claim the reward tokens
        vm.prank(user1);
        supaShrine.claim(user1, claimInfo);
        // assert they got what they should have got
        assert(ISupaERC20(rewardToken).balanceOf(user1) == 7 ether);
    }
}
