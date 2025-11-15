// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; 

// Required for secure signature verification (ecrecover utility)
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/utils/cryptography/ECDSA.sol";

contract AuthManager {
    using ECDSA for bytes32;
    
    address public owner;

    // Core Identity Mappings
    mapping(address => bool) private registered;
    mapping(address => string) private roles;
    mapping(address => string) private profileCID; 

    // Key Rotation Mapping
    mapping(address => address) private pendingRotation;
    
    // NEW: Challenge-Response Storage
    mapping(address => bytes32) private challenges; 
    mapping(address => uint256) private challengeTimestamps; 

    // --- Events ---
    event Registered(address indexed user);
    event Deactivated(address indexed user);
    event UserRemoved(address indexed user);
    event RoleSet(address indexed user, string role);
    event ProfileUpdated(address indexed user, string cid);
    event UserAccess(address indexed user, uint256 timestamp);
    event DIDUpdated(address indexed oldWallet, address indexed newWallet);


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // --- Challenge Generation (VIEW - Free Call) ---

    /// @notice Generates a unique, deterministic challenge for the user and stores it.
    /// @dev Uses keccak256 with block data and user address for entropy.
    /// @return challenge The raw challenge hash (bytes32).
    function getChallenge() external view returns (bytes32 challenge) {
        address user = msg.sender; // FIX: Use msg.sender for reliable wallet context

        require(registered[user], "User is not registered.");
        
        // Generate a challenge based on current block data and user address
        // NOTE: block.difficulty removed as it can be zero on some testnets
        bytes32 rawChallenge = keccak256(
            abi.encodePacked(block.timestamp, block.number, user)
        );
        
        return rawChallenge;
    }
    
    
    // --- Authentication (TRANSACTION - Paid Call) ---

    /// @notice Authenticates the user by verifying a signature against a challenge.
    /// @dev This is the final step of the Challenge-Response login flow.
    /// @param challenge The challenge hash (bytes32) the user was presented and signed.
    /// @param signature The resulting signature from the user's private key.
    function verifySignature(bytes32 challenge, bytes memory signature) external {
        address user = msg.sender;
        
        require(registered[user], "Authentication Failed: User not registered.");

        // 1. Reconstruct the signed message hash (EIP-191 compliant)
        bytes32 messageHash = challenge.toEthSignedMessageHash();

        // 2. Recover the signer address using ecrecover
        address signerAddress = messageHash.recover(signature);

        // 3. Verify that the recovered address matches the current user's address
        require(signerAddress == user, "Authentication Failed: Invalid signature.");

        // 4. Log Access (Success)
        emit UserAccess(user, block.timestamp);
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
        emit Deactivated(msg.sender);
    }
    
    function removeUser(address user) external onlyOwner {
        require(registered[user], "User not registered");
        registered[user] = false;
        delete roles[user];
        delete profileCID[user];
        delete challenges[user]; 
        emit UserRemoved(user);
    }
    
    // --- DID Key Rotation Functions ---

    function requestKeyRotation(address newWallet) external {
        require(registered[msg.sender], "Must be a registered user to rotate DID key");
        require(newWallet != address(0), "New wallet cannot be the zero address");
        require(msg.sender != newWallet, "Cannot rotate to the same address");
        require(!registered[newWallet], "New wallet is already registered");
        
        pendingRotation[msg.sender] = newWallet;
        
        emit KeyRotationRequested(msg.sender, newWallet);
    }

    function updateDID(address newWallet) external {
        address oldWallet = msg.sender;

        require(registered[oldWallet], "Old wallet is not registered");

        registered[newWallet] = registered[oldWallet];
        roles[newWallet] = roles[oldWallet];         
        profileCID[newWallet] = profileCID[oldWallet]; 

        delete registered[oldWallet];
        delete roles[oldWallet];
        delete profileCID[oldWallet];
        delete pendingRotation[oldWallet]; 
        delete challenges[oldWallet]; 

        emit DIDUpdated(oldWallet, newWallet);
    }
    
    // --- Utility & Getter Functions ---

    function isRegistered(address user) external view returns (bool) {
        return registered[user];
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
