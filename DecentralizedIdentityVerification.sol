// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedIdentityVerification {
    struct User {
        bytes32 hashedIdentity;
        bool isVerified;
    }

    mapping(address => User) public users;
    address private admin;

    constructor() {
        admin = msg.sender;
    }

    function addUser(bytes32 _hashedIdentity) public {
        users[msg.sender] = User(_hashedIdentity, false);
    }

    function verifyUser(address _userAddress, bytes32 _hashedIdentity) public {
        require(msg.sender == admin, "Only admin can verify users.");
        require(users[_userAddress].hashedIdentity == _hashedIdentity, "Identity mismatch.");
        users[_userAddress].isVerified = true;
    }
}

