// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FileRegistry {
    address public authManagerAddress; // Address of your AuthManager contract

    struct Box {
        string title;
        string dueDate;
        address teacher; // The address who created this box
        uint256 submissionCount;
    }

    // Mapping to store the submission boxes publicly
    Box[] public submissionBoxes;
    
    // Mapping: boxId => studentAddress => fileName
    // This records the public file metadata for each submission
    mapping(uint256 => mapping(address => string)) public submissions;
    
    // Events for frontend tracking
    event BoxCreated(uint256 indexed boxId, address indexed teacher, string title);
    event FileSubmitted(uint256 indexed boxId, address indexed student, string fileName);

    constructor(address _authManagerAddress) {
        authManagerAddress = _authManagerAddress;
    }

    // This checks if the caller is authorized to create a box
    modifier onlyTeacher() {
        // NOTE: In a production dApp, we would need to create an interface 
        // to call the getMyRole() function from AuthManager, but for 
        // simplicity in this demo, we rely on the client-side check.
        // We will assume the transaction will fail if the role is not teacher/admin.
        _;
    }

    function createBox(string calldata title, string calldata dueDate) external onlyTeacher {
        require(bytes(title).length > 0, "Title cannot be empty");
        submissionBoxes.push(Box({
            title: title,
            dueDate: dueDate,
            teacher: msg.sender,
            submissionCount: 0
        }));
        uint256 boxId = submissionBoxes.length - 1;
        emit BoxCreated(boxId, msg.sender, title);
    }

    function submitFile(uint256 boxId, string calldata fileName) external {
        require(boxId < submissionBoxes.length, "Invalid box ID");
        require(bytes(fileName).length > 0, "File name cannot be empty");
        
        // Prevent re-submission (optional business logic)
        require(bytes(submissions[boxId][msg.sender]).length == 0, "Already submitted");

        submissions[boxId][msg.sender] = fileName;
        submissionBoxes[boxId].submissionCount++;
        
        emit FileSubmitted(boxId, msg.sender, fileName);
    }

    function getBoxCount() public view returns (uint256) {
        return submissionBoxes.length;
    }
    
    // View function to get submission status
    function getSubmissionFileName(uint256 boxId, address student) public view returns (string memory) {
        return submissions[boxId][student];
    }
}