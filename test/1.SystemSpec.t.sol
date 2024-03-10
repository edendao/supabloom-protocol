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

import "forge-std/console.sol";

contract SystemSpecTest is TestSystem {
    event Claim(
        address recipient,
        address indexed claimToken,
        uint256 snapshotId,
        address indexed token,
        address indexed receiver,
        uint256 claimedRewardTokenAmount
    );

    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    string claimTokenName = "Claim Token";
    string claimTokenSymbol = "CT";
    string rewardTokenName = "Reward Token";
    string rewardTokenSymbol = "RT";
    ISchemaRegistry schemaRegistry = ISchemaRegistry(0xA7b39296258348C78294F95B872b282326A97BDF); // Mainnet Schema Registry
    IEAS eas = IEAS(0xA1207F3BBa224E2c9c3c6D5aF63D0eb1582Ce587); // Mainnet EAS
    SupaController controller;
    SupaShrine supaShrine;
    bytes32 claimSchemaUID;
    bytes32 validationSchemaUID;
    address claimToken;
    address rewardToken;

    function setUp() public {
        // Set up a fork of mainnet
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        // Deploy SupaShrine
        supaShrine = new SupaShrine();

        // Deploy SupaController
        controller = new SupaController(eas, address(supaShrine), address(schemaRegistry));

        // Set up a schema for claims with EAS
        // register the schema with our controller with a token name and symbol
        //    this deploys the token but does not mint
        (claimSchemaUID, claimToken) =
            controller.registerSchema("uint256 claimTokenAmount, string data", claimTokenName, claimTokenSymbol);

        // Set up a schema for validations with EAS
        // register the schema with our controller with a token name and symbol
        //    this deploys the token but does not mint
        (validationSchemaUID, rewardToken) =
            controller.registerSchema("uint256 rewardTokenAmount, string data", rewardTokenName, rewardTokenSymbol);
    }

    function testClaiming() public {
        // create a claim attestation with EAS
        uint256 amount = 10 ether;
        string memory data = "data";
        bytes32 claimAttestationUID = eas.attest(
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

        // claim should use the claim schema and the uint256 field is the amount of the token to mint
        // call our controller contract with the claimAttestationID and a receiver address
        controller.claim(claimAttestationUID, address(this));

        //      our controller contract verifies that the claim is not revocable
        // assert that this deployed a SupaERC20 and minted `amount` tokens to the receiver
        assert(ISupaERC20(claimToken).balanceOf(address(this)) == amount);
    }

    function testClaimingIdempotency() public {
        // check token only deployled once
        vm.expectRevert();
        controller.registerSchema("uint256 claimTokenAmount, string data", claimTokenName, claimTokenSymbol);

        uint256 amount = 10 ether;
        string memory data = "data";
        bytes32 claimAttestationUID = eas.attest(
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
        controller.claim(claimAttestationUID, address(this));
        assert(ISupaERC20(claimToken).balanceOf(address(this)) == amount);

        // verify mint only happened one claimAttestationUID.
        vm.expectRevert();
        controller.claim(claimAttestationUID, address(this));
    }

    function _testClaim() internal returns (bytes32 claimAttestationUID) {
        // create a claim attestation with EAS
        uint256 amount = 12 ether;
        string memory data = "data";
        claimAttestationUID = eas.attest(
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

        // controller.claim(claimAttestationID, address receiver)
        //    this mints claim ERC20s to the receiver address, for this test, use address(this) (this test contract)
        controller.claim(claimAttestationUID, address(this));
    }

    function testRewarding() public {
        bytes32 claimAttestationUID = _testClaim();
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");

        assert(ISupaERC20(claimToken).balanceOf(address(this)) == 12 ether);
        // distribute some claim ERC20s to 3 addresses
        ISupaERC20(claimToken).transfer(user1, 4 ether);
        ISupaERC20(claimToken).transfer(user2, 4 ether);
        ISupaERC20(claimToken).transfer(user3, 4 ether);
        assert(ISupaERC20(claimToken).balanceOf(user1) == 4 ether);
        assert(ISupaERC20(claimToken).balanceOf(user2) == 4 ether);
        assert(ISupaERC20(claimToken).balanceOf(user3) == 4 ether);

        // PART 2 — Rewarding ==============
        // create a "reward attestation" on EAS => this is an attestation with refUID = claimAttestationID
        uint256 amount = 21 ether;
        string memory data = "data";
        bytes32 rewardAttestationID = eas.attest(
            AttestationRequest({
                schema: validationSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: claimAttestationUID, // No references UI
                    data: abi.encode(amount, data), // Encode a single uint256 as a parameter to the schema
                    value: 0 // No value/ETH
                })
            })
        );

        // Snapshot number before calling reward function
        uint256 snapshotId = ISupaERC20(claimToken).currentSnapshot();

        // this mints credit `rewardAmount` ERC20s, and calls SupaShrine.reward(claimERC20Token, creditERC20Token, rewardAmount)
        controller.reward(rewardAttestationID, address(controller));
        // assert that a new snapshot was taken of the claimToken ERC20
        // Snapshot number before calling reward function
        uint256 newSnapshotId = ISupaERC20(claimToken).currentSnapshot();
        assert(newSnapshotId == snapshotId + 1);

        // assert that the various holders of the claimToken ERC20s can claim their pro-rata reward
        SupaShrine.ClaimInfo memory claimInfo = SupaShrine.ClaimInfo(newSnapshotId, claimToken, rewardToken, user1);
        assert(supaShrine.claimableTokenAmount(claimInfo, 4 ether) == 7 ether);

        // prank the holders and claim the reward tokens
        vm.prank(user1);
        supaShrine.claim(user1, claimInfo);
        // assert they got what they should have got
        assert(ISupaERC20(rewardToken).balanceOf(user1) == 7 ether);
    }

    function testRewardingIdempotency() public {
        bytes32 claimAttestationUID = _testClaim();
        address user1 = makeAddr("user1");

        assert(ISupaERC20(claimToken).balanceOf(address(this)) == 12 ether);
        // distribute some claim ERC20s to 3 addresses
        ISupaERC20(claimToken).transfer(user1, 4 ether);
        assert(ISupaERC20(claimToken).balanceOf(user1) == 4 ether);

        uint256 amount = 21 ether;
        string memory data = "data";
        bytes32 rewardAttestationID = eas.attest(
            AttestationRequest({
                schema: validationSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: claimAttestationUID, // No references UI
                    data: abi.encode(amount, data), // Encode a single uint256 as a parameter to the schema
                    value: 0 // No value/ETH
                })
            })
        );
        controller.reward(rewardAttestationID, address(controller));
        uint256 newSnapshotId = ISupaERC20(claimToken).currentSnapshot();
        SupaShrine.ClaimInfo memory claimInfo = SupaShrine.ClaimInfo(newSnapshotId, claimToken, rewardToken, user1);
        assert(supaShrine.claimableTokenAmount(claimInfo, 4 ether) == 7 ether);

        // prank the holders and claim the reward tokens
        vm.prank(user1);
        supaShrine.claim(user1, claimInfo);
        // assert they got what they should have got
        assert(ISupaERC20(rewardToken).balanceOf(user1) == 7 ether);

        // verify that claimToken holders cannot claim from the shrine more than once
        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit Claim(user1, claimInfo.claimToken, claimInfo.snapshotId, claimInfo.rewardToken, claimInfo.receiver, 0);
        supaShrine.claim(user1, claimInfo);
        assert(ISupaERC20(rewardToken).balanceOf(user1) == 7 ether);
    }

    function testRewardingAcrossSnapshots() public {
        // this is the same as testRewarding() but move tokens around and take a few snapshots between Part 1 and Part 2 and verify that it all works

        bytes32 claimAttestationUID = _testClaim();
        address user1 = makeAddr("user1");

        assert(ISupaERC20(claimToken).balanceOf(address(this)) == 12 ether);
        // distribute some claim ERC20s to 3 addresses
        ISupaERC20(claimToken).transfer(user1, 4 ether);
        assert(ISupaERC20(claimToken).balanceOf(user1) == 4 ether);

        uint256 amount = 21 ether;
        string memory data = "data";
        bytes32 rewardAttestationID = eas.attest(
            AttestationRequest({
                schema: validationSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: claimAttestationUID, // No references UI
                    data: abi.encode(amount, data), // Encode a single uint256 as a parameter to the schema
                    value: 0 // No value/ETH
                })
            })
        );
        controller.reward(rewardAttestationID, address(controller));
        address user2 = makeAddr("user2");
        ISupaERC20(claimToken).transfer(user2, 4 ether);
        uint256 newSnapshotId = ISupaERC20(claimToken).currentSnapshot();
        SupaShrine.ClaimInfo memory claimInfo1 = SupaShrine.ClaimInfo(newSnapshotId, claimToken, rewardToken, user1);
        SupaShrine.ClaimInfo memory claimInfo2 = SupaShrine.ClaimInfo(newSnapshotId, claimToken, rewardToken, user2);

        vm.prank(user1);
        supaShrine.claim(user1, claimInfo1);
        assert(ISupaERC20(rewardToken).balanceOf(user1) == 7 ether);

        // user2 still doesn't get reward because snapshot was taken before they  got the tokens
        vm.prank(user2);
        supaShrine.claim(user2, claimInfo2);
        assert(ISupaERC20(rewardToken).balanceOf(user2) == 0 ether);
    }
}
