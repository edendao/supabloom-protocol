// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { TestSystem } from "./mixins/TestSystem.sol";
import { ISchemaRegistry } from "@eas/ISchemaRegistry.sol";
import { ISchemaResolver } from "@eas/resolver/ISchemaResolver.sol";
import {
    IEAS,
    AttestationRequest,
    AttestationRequestData
} from "@eas/IEAS.sol";
import { NO_EXPIRATION_TIME, EMPTY_UID } from "@eas/Common.sol";
import { SupaController } from "../src/components/SupaController.sol";
import { ISupaERC20 } from "../src/components/ISupaERC20.sol";

import "forge-std/console.sol";

contract SystemSpecTest is TestSystem {
    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    string claimTokenName = "Claim Token";
    string claimTokenSymbol = "CT";
    string rewardTokenName = "Reward Token";
    string rewardTokenSymbol = "RT";
    ISchemaRegistry schemaRegistry =
        ISchemaRegistry(0xA7b39296258348C78294F95B872b282326A97BDF); // Mainnet Schema Registry
    IEAS eas = IEAS(0xA1207F3BBa224E2c9c3c6D5aF63D0eb1582Ce587); // Mainnet EAS
    SupaController controller;
    bytes32 claimSchemaUID;
    bytes32 validationSchemaUID;
    address claimToken;
    address rewardToken;

    function setUp() public {
        // Set up a fork of mainnet
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);

        // Deploy SupaController
        controller = new SupaController(eas);

        // Set up a schema for claims with EAS
        claimSchemaUID = schemaRegistry.register(
            "uint256 claimTokenAmount",
            ISchemaResolver(address(0)),
            false
        );

        // register the schema with our controller with a token name and symbol
        //    this deploys the token but does not mint
        claimToken = controller.registerSchema(
            claimSchemaUID,
            claimTokenName,
            claimTokenSymbol
        );

        // Set up a schema for validations with EAS
        validationSchemaUID = schemaRegistry.register(
            "uint256 rewardTokenAmount",
            ISchemaResolver(address(0)),
            false
        );

        // register the schema with our controller with a token name and symbol
        //    this deploys the token but does not mint
        rewardToken = controller.registerSchema(
            validationSchemaUID,
            rewardTokenName,
            rewardTokenSymbol
        );
    }

    function testClaiming() public {
        // create a claim attestation with EAS
        uint256 amount = 10 ether;
        bytes32 claimAttestationUID = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: EMPTY_UID, // No references UI
                    data: abi.encode(amount), // Encode a single uint256 as a parameter to the schema
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
        vm.expectRevert(bytes("Token Already Deployed"));
        controller.registerSchema(
            claimSchemaUID,
            claimTokenName,
            claimTokenSymbol
        );

        uint256 amount = 10 ether;
        bytes32 claimAttestationUID = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: EMPTY_UID, // No references UI
                    data: abi.encode(amount), // Encode a single uint256 as a parameter to the schema
                    value: 0 // No value/ETH
                })
            })
        );
        controller.claim(claimAttestationUID, address(this));
        assert(ISupaERC20(claimToken).balanceOf(address(this)) == amount);

        // verfify mint only happened once for a specific token.
        vm.expectRevert(bytes("Token Already Minted"));
        controller.claim(claimAttestationUID, address(this));
    }

    function _testClaim() internal returns (bytes32 claimAttestationUID) {
        // create a claim attestation with EAS
        uint256 amount = 12 ether;
        claimAttestationUID = eas.attest(
            AttestationRequest({
                schema: claimSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: EMPTY_UID, // No references UI
                    data: abi.encode(amount), // Encode a single uint256 as a parameter to the schema
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
        bytes32 rewardAttestationUID = eas.attest(
            AttestationRequest({
                schema: validationSchemaUID,
                data: AttestationRequestData({
                    recipient: address(0), // No recipient
                    expirationTime: NO_EXPIRATION_TIME, // No expiration time
                    revocable: false,
                    refUID: claimAttestationUID, // No references UI
                    data: abi.encode(amount), // Encode a single uint256 as a parameter to the schema
                    value: 0 // No value/ETH
                })
            })
        );
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
