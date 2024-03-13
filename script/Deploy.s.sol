// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "forge-std/Script.sol";

import {ISchemaRegistry} from "@eas/ISchemaRegistry.sol";
import {IEAS, AttestationRequest, AttestationRequestData} from "@eas/IEAS.sol";
import {SupaShrine} from "../src/components/SupaShrine.sol";
import {SupaController} from "../src/components/SupaController.sol";

contract Deployment is Script {

    ISchemaRegistry schemaRegistry = ISchemaRegistry(0xA7b39296258348C78294F95B872b282326A97BDF); // Mainnet Schema Registry
    IEAS eas = IEAS(0xA1207F3BBa224E2c9c3c6D5aF63D0eb1582Ce587); // Mainnet EAS

    function run() external {
        vm.startBroadcast();
        
        // Deploy SupaShrine
        SupaShrine supaShrine = new SupaShrine();

        // Deploy SupaController
        new SupaController(eas, address(supaShrine), address(schemaRegistry));

        vm.stopBroadcast();
    }
}

// $ forge script script/Deployment.s.sol --broadcast --fork-url $RPC_URL --private-key $PRIVATE_KEY
