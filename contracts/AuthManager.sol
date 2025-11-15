// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuthManager {
    address public owner;

    mapping(address => bool) private registered;
    mapping(address => string) private roles;
    mapping(address => string) private profileCID;

    mapping(address => bytes32) private activeChallenges; // Stores current login challenges
    mapping(address => address) private pendingRotation;

    event Registered(address indexed user);
    event Deactivated(address indexed user);
    event UserRemoved(address indexed user);
    event RoleSet(address indexed user, string role);
    event ProfileUpdated(address indexed user, string cid);
    event UserAccess(address indexed user, uint256 timestamp);
    event KeyRotationRequested(address indexed oldWallet, address indexed newWallet);
    event DIDUpdated(address indexed oldWallet, address indexed newWallet);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // -----------------------------
    // Core Identity Functions
    // -----------------------------
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
        delete roles[user];
        delete profileCID[user];
        emit UserRemoved(user);
    }

    // -----------------------------
    // Challenge-Response Authentication
    // -----------------------------
    function getChallenge() external returns (bytes32) {
        require(registered[msg.sender], "User not registered");

        // Generate a pseudo-random challenge using block.timestamp + address
        bytes32 challenge = keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender));
        activeChallenges[msg.sender] = challenge;
        return challenge;
    }

    function verifySignature(bytes32 challenge, bytes memory signature) external {
        require(registered[msg.sender], "User not registered");
        require(activeChallenges[msg.sender] == challenge, "Invalid or expired challenge");

        // Ethereum signed message prefix
        bytes32 ethSignedMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", challenge)
        );

        // Recover signer
        address signer = recoverSigner(ethSignedMessage, signature);
        require(signer == msg.sender, "Invalid signature");

        // Authentication successful → log access
        emit UserAccess(msg.sender, block.timestamp);

        // Clear challenge to prevent replay
        delete activeChallenges[msg.sender];
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // -----------------------------
    // DID Key Rotation Functions
    // -----------------------------
    function requestKeyRotation(address newWallet) external {
        require(registered[msg.sender], "Must be registered");
        require(newWallet != address(0), "New wallet zero");
        require(newWallet != msg.sender, "Cannot rotate to same wallet");
        require(!registered[newWallet], "New wallet already registered");

        pendingRotation[msg.sender] = newWallet;
        emit KeyRotationRequested(msg.sender, newWallet);
    }

    function updateDID(address newWallet) external {
        address oldWallet = msg.sender;
        require(registered[oldWallet], "Old wallet not registered");

        registered[newWallet] = registered[oldWallet];
        roles[newWallet] = roles[oldWallet];
        profileCID[newWallet] = profileCID[oldWallet];

        delete registered[oldWallet];
        delete roles[oldWallet];
        delete profileCID[oldWallet];
        delete pendingRotation[oldWallet];

        emit DIDUpdated(oldWallet, newWallet);
    }

    // -----------------------------
    // Utility Functions
    // -----------------------------
    function isRegistered(address user) external view returns (bool) {
        return registered[user];
    }

    function logAccess() external {
        require(registered[msg.sender], "Must be registered");
        emit UserAccess(msg.sender, block.timestamp);
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
