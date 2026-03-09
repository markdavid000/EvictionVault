// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../lib/forge-std/src/Test.sol";
import "../src/EvictionVault.sol";

contract EvictionVaultTest is Test {

    EvictionVault vault;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);

    address user = address(0x4);

    function setUp() public {

        address[] memory owners = new address[](3);

        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        vault = new EvictionVault{value: 5 ether}(owners, 2);
    }

    function testDeposit() public {

        vm.deal(user, 1 ether);

        vm.prank(user);
        vault.deposit{value: 1 ether}();

        assertEq(vault.balances(user), 1 ether);
        assertEq(vault.totalVaultValue(), 6 ether);
    }

    function testWithdraw() public {

        vm.deal(user, 2 ether);

        vm.startPrank(user);
        vault.deposit{value: 1 ether}();

        uint256 balanceBefore = user.balance;

        vault.withdraw(1 ether);

        uint256 balanceAfter = user.balance;

        assertEq(balanceAfter, balanceBefore + 1 ether);
    }

    function testPauseBlocksWithdraw() public {

        vm.prank(owner1);
        vault.pause();

        vm.deal(user, 1 ether);

        vm.startPrank(user);
        vault.deposit{value: 1 ether}();

        vm.expectRevert("paused");
        vault.withdraw(1 ether);
    }

    function testMultisigExecution() public {

        vm.deal(address(vault), 1 ether);

        bytes memory data = "";

        vm.prank(owner1);
        vault.submitTransaction(user, 1 ether, data);

        vm.prank(owner2);
        vault.confirmTransaction(0);

        vm.warp(block.timestamp + 1 hours + 1);

        uint256 balanceBefore = user.balance;

        vault.executeTransaction(0);

        assertEq(user.balance, balanceBefore + 1 ether);
    }

    function testTimelockPreventsEarlyExecution() public {

        vm.deal(address(vault), 1 ether);

        vm.prank(owner1);
        vault.submitTransaction(user, 1 ether, "");

        vm.prank(owner2);
        vault.confirmTransaction(0);

        vm.expectRevert("timelock active");
        vault.executeTransaction(0);
    }

    function testSetMerkleRoot() public {

        bytes32 root = keccak256("root");

        vm.prank(owner1);
        vault.setMerkleRoot(root);

        assertEq(vault.merkleRoot(), root);
    }
}