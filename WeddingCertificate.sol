// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract WeddingCertificate is ERC721 {
    constructor() ERC721("WeddingCertificate", "WEDCERT") {}

    function mintCertificate(address to, uint256 tokenId) public
    {
        // In case I need to store more information, do it here

        _mint(to, tokenId);
    }

    function burnCertificate(uint256 tokenId) public {
        _burn(tokenId);
        // Clean up information
    }

    // Override to prevent transferring tokens (make it an NTT)
    function _transferCertificate(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal pure 
    {
        revert("WeddingCertificate: transfer not allowed");
    }
}

