// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

error Migrations__NotOwner();

contract Migrations {
    address public owner = msg.sender;
    uint256 public last_completed_migration;

    modifier restricted() {
        if (msg.sender != owner) {
            revert Migrations__NotOwner();
        }
        _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }
}
