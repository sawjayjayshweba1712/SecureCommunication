// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PublicWall {
    struct Post {
        address author;
        string text;
        uint256 timestamp;
        bool isDeleted; // NEW: Flag to mark as deleted
    }

    Post[] private posts;

    event PostCreated(uint256 indexed index, address indexed author, uint256 timestamp, string text);
    event PostDeleted(uint256 indexed index, address indexed author); // NEW: Event for deletion

    /// @notice Add a new post to the wall
    function addPost(string calldata _text) external {
        require(bytes(_text).length > 0, "Empty post not allowed");
        posts.push(Post({
            author: msg.sender,
            text: _text,
            timestamp: block.timestamp,
            isDeleted: false // NEW: Set flag on creation
        }));
        emit PostCreated(posts.length - 1, msg.sender, block.timestamp, _text);
    }

    /// @notice Returns total number of posts
    function getPostCount() external view returns (uint256) {
        return posts.length;
    }

    /// @notice Returns single post by index, including deletion status
    function getPost(uint256 index) external view returns (address author, string memory text, uint256 timestamp, bool isDeleted) {
        require(index < posts.length, "Index out of bounds");
        Post storage p = posts[index];
        return (p.author, p.text, p.timestamp, p.isDeleted);
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