// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "./VaultStorage.sol";

abstract contract VaultMerkleClaims is VaultStorage {

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount)
        external
        whenNotPaused
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

        require(
            MerkleProof.verify(proof, merkleRoot, leaf),
            "invalid proof"
        );

        require(!claimed[msg.sender], "already claimed");

        claimed[msg.sender] = true;

        totalVaultValue -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");

        emit Claim(msg.sender, amount);
    }
}