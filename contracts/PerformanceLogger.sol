// PerformanceLogger.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PerformanceLogger {
    // Only the owner of the logging contract can call these functions
    address private owner;
    
    // --- Data Structures ---
    
    // Logs for passwordless authentication performance
    struct AuthLog {
        uint256 durationMs; // Time from nonce request to final verification (in milliseconds)
        uint256 timestamp;
        address user;
    }
    
    // Logs for transaction performance
    struct TxLog {
        uint256 durationMs;  // Time from tx send to confirmation
        uint256 gasUsed;     // Gas used by the transaction
        string functionName; // e.g., "register", "deactivateAccount"
        uint256 timestamp;
        address user;
    }

    // --- Storage ---
    AuthLog[] public authLogs;
    TxLog[] public txLogs;
    
    // --- Events ---
    event AuthPerformanceLogged(address indexed user, uint256 durationMs, uint256 timestamp);
    event TxPerformanceLogged(address indexed user, string functionName, uint256 gasUsed, uint256 durationMs, uint256 timestamp);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    
    /// @notice Logs the duration of a successful passwordless authentication flow.
    /// @dev Called by the contract owner (admin wallet) to log performance for a user.
    function logAuthenticationTime(address user, uint256 durationMs) external onlyOwner {
        authLogs.push(AuthLog(
            durationMs,
            block.timestamp,
            user
        ));
        emit AuthPerformanceLogged(user, durationMs, block.timestamp);
    }
    
    /// @notice Logs the performance metrics for a state-changing transaction.
    /// @dev Called by the contract owner (admin wallet) to log performance for a user.
    function logTransactionPerformance(
        address user,
        string calldata functionName, 
        uint256 gasUsed, 
        uint256 durationMs
    ) external onlyOwner {
        txLogs.push(TxLog(
            durationMs,
            gasUsed,
            functionName,
            block.timestamp,
            user
        ));
        emit TxPerformanceLogged(user, functionName, gasUsed, durationMs, block.timestamp);
    }

    // --- Getter Functions for Dashboard ---
    
    /// @notice Filters and returns all authentication logs for a specific user.
    function getAuthLogsByUser(address user) external view returns (AuthLog[] memory) {
        AuthLog[] memory filteredLogs = new AuthLog[](authLogs.length);
        uint256 count = 0;
        for (uint256 i = 0; i < authLogs.length; i++) {
            if (authLogs[i].user == user) {
                filteredLogs[count] = authLogs[i];
                count++;
            }
        }
        // Resize array to fit actual count
        AuthLog[] memory result = new AuthLog[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = filteredLogs[i];
        }
        return result;
    }
    
    /// @notice Filters and returns all transaction logs for a specific user.
    function getTxLogsByUser(address user) external view returns (TxLog[] memory) {
         TxLog[] memory filteredLogs = new TxLog[](txLogs.length);
        uint256 count = 0;
        for (uint256 i = 0; i < txLogs.length; i++) {
            if (txLogs[i].user == user) {
                filteredLogs[count] = txLogs[i];
                count++;
            }
        }
        // Resize array to fit actual count
        TxLog[] memory result = new TxLog[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = filteredLogs[i];
        }
        return result;
    }
}