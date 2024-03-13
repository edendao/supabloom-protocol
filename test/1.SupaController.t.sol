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

contract SupaControllerTest is TestSystem {

    uint256 mainnetFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    ISchemaRegistry schemaRegistry = ISchemaRegistry(0xA7b39296258348C78294F95B872b282326A97BDF); // Mainnet Schema Registry
    IEAS eas = IEAS(0xA1207F3BBa224E2c9c3c6D5aF63D0eb1582Ce587); // Mainnet EAS
    SupaController controller;
    SupaShrine supaShrine;

    function setUp() public {

        // Set up a fork of mainnet
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);

        // Deploy SupaShrine
        supaShrine = new SupaShrine();

        // Deploy SupaController
        controller = new SupaController(eas, address(supaShrine), address(schemaRegistry));
    }

    function testRegisterSchema() public {
        // Register schema and deploy token
        (, address token) = controller.registerSchema("schema", "name", "symbol");
        assert(token != address(0));
    }
    function testClaim() public { 
        (bytes32 claimSchemaUID, address claimToken) = controller.registerSchema(
            "uint256 claimTokenAmount, string data",
            "Claim Token",
            "CT"
        );
        
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
    }

    function testReward() public { 
        (bytes32 claimSchemaUID, address claimToken) = controller.registerSchema(
            "uint256 claimTokenAmount, string data",
            "Claim Token",
            "CT"
        );
        
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

        (bytes32 validationSchemaUID, address rewardToken) = controller.registerSchema(
            "uint256 rewardTokenAmount, string data",
            "Reward Token",
            "RT"
        );

        amount = 10 ether;
        data = "data";
        bytes32 rewardAttestationID1 = eas.attest(
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
        controller.reward(rewardAttestationID1, address(controller));
        // assert that a new snapshot was taken of the claimToken ERC20
        // Snapshot number before calling reward function
        uint256 newSnapshotId = ISupaERC20(claimToken).currentSnapshot();
        assert(newSnapshotId == snapshotId + 1);
        // assert that the various holders of the claimToken ERC20s can claim their pro-rata reward
        SupaShrine.ClaimInfo memory claimInfo = SupaShrine.ClaimInfo(
            newSnapshotId,
            claimToken,
            rewardToken,
            address(this)
        );
        supaShrine.claim(address(this), claimInfo);
        // assert they got what they should have got
        assert(ISupaERC20(rewardToken).balanceOf(address(this)) == 10 ether);
     }
}
