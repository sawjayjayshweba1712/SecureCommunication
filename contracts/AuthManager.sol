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

    // Key Rotation Mapping (Old Address => New Address)
    mapping(address => address) private pendingRotation;

    // --- Events ---
    event Registered(address indexed user);
    event Deactivated(address indexed user);
    event UserRemoved(address indexed user);
    event RoleSet(address indexed user, string role);
    event ProfileUpdated(address indexed user, string cid);
    event UserAccess(address indexed user, uint256 timestamp);
    event Authenticated(address indexed user, uint256 timestamp, uint256 nonce);
    
    // Key Rotation Events
    event KeyRotationRequested(address indexed oldWallet, address indexed newWallet);
    event DIDUpdated(address indexed oldWallet, address indexed newWallet);

    // --- Internal Helpers ---
    
    // Minimal ecrecover implementation
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) return address(0);

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) v += 27;

        return ecrecover(hash, v, r, s);
    }

    // NEW: Minimal uint256 to string conversion (needed for EIP-191 prefixing logic)
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    // --- Core Logic ---
    
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
        nonces[msg.sender] = 0;
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
        delete nonces[user];
        delete roles[user];
        delete profileCID[user];
        emit UserRemoved(user);
    }
    
    function getNonce(address user) external view returns (uint256) {
        require(registered[user], "User not registered");
        return nonces[user];
    }
    
    /// @notice Performs secure Challenge-Response authentication using the user's signature.
    /// CRITICAL FIX: The contract now re-prefixes the hash to match Ethers' signer.signMessage().
    function authenticateWithSignature(bytes calldata signature) external {
        address user = msg.sender;
        require(registered[user], "Authentication Failed: User not registered");
        
        uint256 currentNonce = nonces[user];
        
        // 1. Reconstruct the exact string message the frontend signed.
        string memory message = string(
            abi.encodePacked("UniversityPortalLogin:", toString(currentNonce))
        );
        
        // 2. Compute the EIP-191 prefixed hash (matching Ethers' signMessage logic).
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        bytes memory messageBytes = bytes(message);
        
        bytes32 prefixedHash = keccak256(
            abi.encodePacked(prefix, toString(messageBytes.length), message)
        );
        
        // 3. Recover the address from the prefixed hash and signature.
        address recoveredAddress = recover(prefixedHash, signature);
        
        require(recoveredAddress == user, "Authentication Failed: Invalid signature or message");
        
        // 4. Success!
        nonces[user] = nonces[user] + 1;
        emit Authenticated(user, block.timestamp, currentNonce);
        emit UserAccess(user, block.timestamp);
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
        nonces[newWallet] = nonces[oldWallet]; // Transfer the nonce

        delete registered[oldWallet];
        delete nonces[oldWallet];
        delete roles[oldWallet];
        delete profileCID[oldWallet];
        delete pendingRotation[oldWallet]; 

        emit DIDUpdated(oldWallet, newWallet);
    }
    
    // --- Utility & Getter Functions ---

    function isRegistered(address user) external view returns (bool) {
        return registered[user];
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