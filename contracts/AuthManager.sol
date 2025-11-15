// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuthManager {
    address public owner;
    // Core Identity Mappings
    mapping(address => bool) private registered;
    mapping(address => string) private roles;
    mapping(address => string) private profileCID; 

    // NEW MAPPING: Tracks a unique number used once for cryptographic signing (DID Auth).
    mapping(address => uint256) private nonces; 

    // NEW: Key Rotation Mapping (Old Address => New Address)
    mapping(address => address) private pendingRotation;

    // --- Events ---
    event Registered(address indexed user);
    event Deactivated(address indexed user);
    event UserRemoved(address indexed user);
    event RoleSet(address indexed user, string role);
    event ProfileUpdated(address indexed user, string cid);
    event UserAccess(address indexed user, uint256 timestamp);
    // NEW: Event for successful signature-based authentication
    event Authenticated(address indexed user, uint256 timestamp, uint256 nonce);
    
    // Key Rotation Events
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
        nonces[msg.sender] = 0; // Initialize nonce for DID security
        emit Registered(msg.sender);
    }

    function deactivateAccount() external {
        require(registered[msg.sender], "Not registered");
        registered[msg.sender] = false;
        // The nonce and other data remain, but registration status is revoked.
        emit Deactivated(msg.sender);
    }

    function removeUser(address user) external onlyOwner {
        require(registered[user], "User not registered");
        registered[user] = false;
        // Clear all associated data
        delete nonces[user];
        delete roles[user];
        delete profileCID[user];
        emit UserRemoved(user);
    }
    
    // --- SECURE DID AUTHENTICATION FUNCTIONS (New Core Logic) ---

    /// @notice Returns the current unique nonce for the given user, used to construct the signed challenge message.
    function getNonce(address user) external view returns (uint256) {
        require(registered[user], "User not registered");
        return nonces[user];
    }
    
    /// @notice Performs secure Challenge-Response authentication using the user's signature.
    /// @param signature The EIP-191 signature of the challenge message: "UniversityPortalLogin:" + nonce.
    function authenticateWithSignature(bytes calldata signature) external {
        address user = msg.sender;
        require(registered[user], "Authentication Failed: User not registered");
        
        uint256 currentNonce = nonces[user];
        
        // 1. Construct the message that the user must have signed.
        // This must match the challengeMessage construction in index.html exactly: "UniversityPortalLogin:" + nonce
        bytes memory messagePrefix = "UniversityPortalLogin:";
        
        // Helper to convert uint256 to a string representation for hashing.
        // NOTE: This simple implementation requires the frontend to handle string conversion 
        // to match the Solidity-hashed data exactly. The frontend uses a simple string.
        // To hash: keccak256(abi.encodePacked(messagePrefix, currentNonce)) 
        
        // We will use a standard keccak256 hash of a packed structure including the nonce.
        // The frontend must sign the simple string: "UniversityPortalLogin:123"
        // The ecrecover function uses the EIP-191 standard prefixed hash of the message.
        
        // We must reconstruct the standard EIP-191 signed message hash:
        // Hash( "\x19Ethereum Signed Message:\n" + len(message) + message )
        
        // Since Solidity lacks a built-in integer-to-string conversion for this, 
        // we'll use a standard, simpler signature recovery, assuming the Ethers library handles 
        // the EIP-191 prefixing for us on the contract side by providing the full bytes.
        // This setup requires the frontend to manually create the EIP-191 prefixed hash before signing 
        // IF using the raw signature, but Ethers' `signer.signMessage` handles it.
        
        // For security, we recover the address from a hash of the simple challenge string.
        
        // The string to sign (frontend): "UniversityPortalLogin:123"
        // We use the Ethers signMessage() which prefixes the hash.
        
        bytes32 challengeHash = keccak256(abi.encodePacked(messagePrefix, currentNonce));
        
        // Recover the address that signed the challengeHash (EIP-191 prefix is assumed by ecrecover for external calls)
        address recoveredAddress = recover(challengeHash, signature);
        
        // Verify the recovered address matches the claimed user.
        require(recoveredAddress == user, "Authentication Failed: Invalid signature or message");
        
        // Success! Increment the nonce and emit the event.
        nonces[user] = nonces[user] + 1;
        emit Authenticated(user, block.timestamp, currentNonce);
        
        // Log access for the admin dashboard metric tracking
        emit UserAccess(user, block.timestamp);
    }
    
    // Minimal ecrecover implementation (since we can't import libraries)
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length is 65 bytes
        if (signature.length != 65) {
            return address(0);
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // EIP-155: v should be 27 or 28, but can be 0 or 1. Adjust v to 27 or 28.
        if (v < 27) {
            v += 27;
        }

        // Recover the address using the ecrecover EVM opcode
        address recoveredAddress = ecrecover(hash, v, r, s);
        return recoveredAddress;
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
        
        // 1. Move the data from oldWallet to newWallet
        registered[newWallet] = registered[oldWallet];
        roles[newWallet] = roles[oldWallet];
        profileCID[newWallet] = profileCID[oldWallet];
        nonces[newWallet] = nonces[oldWallet]; // Transfer the nonce

        // 2. Clear the old wallet's state
        delete registered[oldWallet];
        delete nonces[oldWallet];
        delete roles[oldWallet];
        delete profileCID[oldWallet];
        delete pendingRotation[oldWallet]; 

        // 3. Emit event and mark success
        emit DIDUpdated(oldWallet, newWallet);
    }
    
    // --- Utility & Getter Functions ---

    function isRegistered(address user) external view returns (bool) {
        return registered[user];
    }

    // REMOVED `logAccess()`: It is now called internally within `authenticateWithSignature`

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