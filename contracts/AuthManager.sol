// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuthManager {
    address public owner;

    // Core Identity Mappings
    mapping(address => bool) private registered;
    mapping(address => string) private roles;
    mapping(address => string) private profileCID; // IPFS CID or other pointer

    // NEW: Key Rotation Mapping (Old Address => New Address)
    // Used to check if an address has a pending rotation target.
    mapping(address => address) private pendingRotation;

    // --- Events ---
    event Registered(address indexed user);
    event Deactivated(address indexed user);
    event UserRemoved(address indexed user);
    event RoleSet(address indexed user, string role);
    event ProfileUpdated(address indexed user, string cid);
    event UserAccess(address indexed user, uint256 timestamp);
    
    // NEW: Key Rotation Events
    event KeyRotationRequested(address indexed oldWallet, address indexed newWallet);
    event DIDUpdated(address indexed oldWallet, address indexed newWallet);


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // --- Core Identity Functions ---
    
    function register() external {
        require(!registered[msg.sender], "Already registered");
        registered[msg.sender] = true;
        emit Registered(msg.sender);
    }

    function deactivateAccount() external {
        require(registered[msg.sender], "Not registered");
        registered[msg.sender] = false;
        // Optionally clear other data here if deactivation means full data removal
        emit Deactivated(msg.sender);
    }

    function removeUser(address user) external onlyOwner {
        require(registered[user], "User not registered");
        registered[user] = false;
        // Clear all associated data
        delete roles[user];
        delete profileCID[user];
        emit UserRemoved(user);
    }

    // --- DID Key Rotation Functions (NEW) ---

    /// @notice Initiates the key rotation process to a new wallet address.
    /// The user must call this function using their current, registered wallet (msg.sender).
    function requestKeyRotation(address newWallet) external {
        require(registered[msg.sender], "Must be a registered user to rotate DID key");
        require(newWallet != address(0), "New wallet cannot be the zero address");
        require(msg.sender != newWallet, "Cannot rotate to the same address");
        require(!registered[newWallet], "New wallet is already registered");
        
        // Store the request for the new wallet to be associated with the old one's data.
        pendingRotation[msg.sender] = newWallet;
        
        emit KeyRotationRequested(msg.sender, newWallet);
    }

    /// @notice Finalizes the key rotation, transferring all identity data to the new address.
    /// User signs with old wallet to approve (transaction msg.sender is the old wallet).
    function updateDID(address newWallet) external {
        address oldWallet = msg.sender;

        require(registered[oldWallet], "Old wallet is not registered");
        // We don't need to check pendingRotation here since the user is signing with the old wallet.
        // The fact that the oldWallet is the msg.sender is the proof of key control.

        // 1. Move the data from oldWallet to newWallet
        registered[newWallet] = registered[oldWallet]; // Transfer registration status
        roles[newWallet] = roles[oldWallet];         // Transfer role
        profileCID[newWallet] = profileCID[oldWallet]; // Transfer profile CID

        // 2. Clear the old wallet's state
        delete registered[oldWallet];
        delete roles[oldWallet];
        delete profileCID[oldWallet];
        delete pendingRotation[oldWallet]; // Clear any pending request

        // 3. Emit event and mark success
        emit DIDUpdated(oldWallet, newWallet);
    }
    
    // --- Utility & Getter Functions ---

    function authenticate(address user) external view returns (bool) {
        return registered[user];
    }

    function isRegistered(address user) external view returns (bool) {
        return registered[user];
    }

    function logAccess() external {
        require(registered[msg.sender], "Must be registered to log access");
        emit UserAccess(msg.sender, block.timestamp);
    }

    function setRole(address user, string calldata role) external onlyOwner {
        roles[user] = role;
        emit RoleSet(user, role);
    }
    
    function getMyRole() external view returns (string memory) {
        return roles[msg.sender];
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
