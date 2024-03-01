// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {Test} from "forge-std/Test.sol";
import {SupaERC20} from "../src/components/SupaERC20.sol";

contract SupaERC20Test is Test {
    SupaERC20 token;
    address owner1 = makeAddr("owner1");
    address owner2 = makeAddr("owner2");

    function setUp() public {
        token = new SupaERC20("Test", "T", owner1, owner2);
    }

    function testSnapshot() public {
        uint256 snapshotId = token.currentSnapshot();
        assertEq(snapshotId, 0);
        token.incrementSnapshot();
        snapshotId = token.currentSnapshot();
        assertEq(snapshotId, 1);
    }

    function testMint() public {
        vm.prank(owner1);
        token.mint(owner1, 100);
        assertEq(token.balanceOf(owner1), 100);
    }
}
