// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./VaultStorage.sol";
import "./VaultMultiSig.sol";
import "./VaultMerkleClaims.sol";

contract EvictionVault is VaultStorage, VaultMultiSig, VaultMerkleClaims {

    constructor(address[] memory _owners, uint256 _threshold) payable {

        require(_owners.length > 0, "no owners");
        require(_threshold <= _owners.length, "invalid threshold");

        threshold = _threshold;

        for (uint i = 0; i < _owners.length; i++) {

            address owner = _owners[i];

            require(owner != address(0), "zero owner");
            require(!isOwner[owner], "duplicate owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        totalVaultValue = msg.value;
    }

    receive() external payable {

        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {

        require(msg.value > 0, "can't deposit zero value");
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount)
        external
        whenNotPaused
    {
        require(balances[msg.sender] >= amount, "insufficient");

        balances[msg.sender] -= amount;
        totalVaultValue -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function emergencyWithdrawAll(address receiver)
        external
        onlyOwner
    {
        require(receiver != address(0), "address zero detected");
        
        uint256 bal = address(this).balance;

        (bool success,) = receiver.call{value: bal}("");
        require(success, "withdrwal failed");

        totalVaultValue = 0;
    }
}