// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PublicWall {
    struct Post {
        address author;
        string text;
        uint256 timestamp;
    }

    Post[] private posts;

    event PostCreated(uint256 indexed index, address indexed author, uint256 timestamp, string text);

    /// @notice Add a new post to the wall
    function addPost(string calldata _text) external {
        require(bytes(_text).length > 0, "Empty post not allowed");
        posts.push(Post({
            author: msg.sender,
            text: _text,
            timestamp: block.timestamp
        }));
        emit PostCreated(posts.length - 1, msg.sender, block.timestamp, _text);
    }

    /// @notice Returns total number of posts
    function getPostCount() external view returns (uint256) {
        return posts.length;
    }

    /// @notice Returns single post by index
    function getPost(uint256 index) external view returns (address author, string memory text, uint256 timestamp) {
        require(index < posts.length, "Index out of bounds");
        Post storage p = posts[index];
        return (p.author, p.text, p.timestamp);
    }
}
