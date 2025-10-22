// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuthManager {
    address public owner;

    mapping(address => bool) private registered;
    mapping(address => string) private roles;
    mapping(address => string) private profileCID; // IPFS CID or other pointer

    event Registered(address indexed user);
    event Deactivated(address indexed user);
    event UserRemoved(address indexed user);
    event RoleSet(address indexed user, string role);
    event ProfileUpdated(address indexed user, string cid);
    event UserAccess(address indexed user, uint256 timestamp); // NEW: Event for logging

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function register() external {
        require(!registered[msg.sender], "Already registered");
        registered[msg.sender] = true;
        emit Registered(msg.sender);
    }

    function deactivateAccount() external {
        require(registered[msg.sender], "Not registered");
        registered[msg.sender] = false;
        emit Deactivated(msg.sender);
    }

    function removeUser(address user) external onlyOwner {
        require(registered[user], "User not registered");
        registered[user] = false;
        emit UserRemoved(user);
    }

    function authenticate(address user) external view returns (bool) {
        // Checks if a user is registered (still free to call)
        return registered[user];
    }

    function isRegistered(address user) external view returns (bool) {
        return registered[user];
    }

    // NEW: Function to log access (requires a transaction)
    function logAccess() external {
        require(registered[msg.sender], "Must be registered to log access");
        emit UserAccess(msg.sender, block.timestamp);
    }

    function setRole(address user, string calldata role) external onlyOwner {
        roles[user] = role;
        emit RoleSet(user, role);
    }

    function getRole(address user) external view returns (string memory) {
        return roles[user];
    }

    function setProfileCID(string calldata cid) external {
        require(registered[msg.sender], "Not registered");
        profileCID[msg.sender] = cid;
        emit ProfileUpdated(msg.sender, cid);
    }

    function getProfileCID(address user) external view returns (string memory) {
        return profileCID[user];
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}