// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./VaultStorage.sol";

abstract contract VaultMultiSig is VaultStorage {
    function submitTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyOwner whenNotPaused {

        uint256 id = txCount++;

        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });

        confirmed[id][msg.sender] = true;

        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external onlyOwner whenNotPaused {

        Transaction storage txn = transactions[txId];

        require(!txn.executed, "executed");
        require(!confirmed[txId][msg.sender], "already confirmed");

        confirmed[txId][msg.sender] = true;
        txn.confirmations++;

        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }

        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {

        Transaction storage txn = transactions[txId];

        require(txn.confirmations >= threshold, "not enough confirmations");
        require(!txn.executed, "already executed");
        require(txn.executionTime != 0, "timelock not set");
        require(block.timestamp >= txn.executionTime, "timelock active");

        txn.executed = true;

        (bool success,) = txn.to.call{value: txn.value}(txn.data);
        require(success, "tx failed");

        emit Execution(txId);
    }

    function pause() external onlyOwner {
        require(msg.sender == address(this), "only multisig");
        paused = true;
    }

    function unpause() external onlyOwner {
        require(msg.sender == address(this), "only multisig");
        paused = false;
    }
}
