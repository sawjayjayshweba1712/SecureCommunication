// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // Increased to 0.8.20 for consistency with other files

contract PublicWall {

    // NEW STRUCT: To hold comment data
    struct Comment {
        address author;
string text;
        uint256 timestamp;
    }

    struct Post {
        address author;
string text;
        uint256 timestamp;
        bool isDeleted;
        // NEW FIELDS
        Comment[] comments;
// Array to hold all comments for this post
        mapping(address => bool) reacted;
// Simple reaction: tracks if an address has liked/reacted once
        uint256 reactionCount;
// Counter for total reactions
    }

    Post[] private posts;
// UPDATED EVENTS
    event PostCreated(uint256 indexed index, address indexed author, uint256 timestamp, string text);
event PostDeleted(uint256 indexed index, address indexed author);
    event CommentAdded(uint256 indexed postIndex, address indexed author, uint256 timestamp, string text);
// NEW
    event ReactionToggled(uint256 indexed postIndex, address indexed user, bool added);
// NEW

    /// @notice Add a new post to the wall
    function addPost(string calldata _text) external {
        require(bytes(_text).length > 0, "Empty post not allowed");
// 1. Add an empty Post struct to the storage array
        posts.push();
uint256 newIndex = posts.length - 1;
        
        // 2. Access the storage slot and update the fields individually.
// Mappings (like 'reacted') are automatically handled by storage.
        Post storage newPost = posts[newIndex];
        
        newPost.author = msg.sender;
        newPost.text = _text;
newPost.timestamp = block.timestamp;
        newPost.isDeleted = false;
        newPost.reactionCount = 0; // Initialize counter
        // newPost.comments is initialized as an empty dynamic array

        emit PostCreated(newIndex, msg.sender, block.timestamp, _text);
}
    /// @notice Adds a comment to a specific post index
    function addComment(uint256 index, string calldata _text) external {
        require(index < posts.length, "Index out of bounds");
require(!posts[index].isDeleted, "Post is deleted");
        require(bytes(_text).length > 0, "Comment cannot be empty");
posts[index].comments.push(
            Comment(msg.sender, _text, block.timestamp)
        );
emit CommentAdded(index, msg.sender, block.timestamp, _text);
    }

    /// @notice Toggles a simple reaction (like/unlike) for a post
    function toggleReaction(uint256 index) external {
        require(index < posts.length, "Index out of bounds");
require(!posts[index].isDeleted, "Post is deleted");
        
        // Toggle the reaction status
        if (posts[index].reacted[msg.sender]) {
            posts[index].reacted[msg.sender] = false;
posts[index].reactionCount--;
            emit ReactionToggled(index, msg.sender, false);
        } else {
            posts[index].reacted[msg.sender] = true;
posts[index].reactionCount++;
            emit ReactionToggled(index, msg.sender, true);
        }
    }

    /// @notice Returns total number of posts
    function getPostCount() external view returns (uint256) {
        return posts.length;
}

    /// @notice Returns single post by index, including comments and reactions
    // NOTE: This replaces the original getPost function signature
    function getPostDetails(uint256 index) external view returns (
        address author, 
        string memory text, 
        uint256 timestamp, 
        bool isDeleted,
        Comment[] memory comments,       
       
 uint256 reactionCount           
    ) {
        require(index < posts.length, "Index out of bounds");
Post storage p = posts[index];
        return (
            p.author, 
            p.text, 
            p.timestamp, 
            p.isDeleted,
            p.comments, 
            p.reactionCount
        );
}

    /// @notice Allows the author to mark their post as deleted
    function deletePost(uint256 index) external {
        require(index < posts.length, "Index out of bounds");
Post storage p = posts[index];
        
        require(p.author == msg.sender, "Only the author can delete this post");
        require(!p.isDeleted, "Post is already deleted");
p.isDeleted = true;
        emit PostDeleted(index, msg.sender);
    }
}


