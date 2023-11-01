// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WeddingCertificate is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    struct Certificate {
        address spouse1;
        address spouse2;
        string externalDataURI; // Link to a larger data file
    }

    mapping(uint256 => Certificate) public certificateDetails;

    constructor() ERC721("WeddingCertificate", "WCT") {}

    function mint(address _spouse1, address _spouse2) external onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(_spouse1, newTokenId);
        certificateDetails[newTokenId] = Certificate({
            spouse1: _spouse1,
            spouse2: _spouse2,
            externalDataURI: "" // Can be set later or during minting as required
        });
    }

    function setExternalDataURI(uint256 _tokenId, string calldata _externalDataURI) external {
        require(ownerOf(_tokenId) == msg.sender, "Not the owner");
        certificateDetails[_tokenId].externalDataURI = _externalDataURI;
    }

    function burnCertificate(uint256 _tokenId, address _authorisedAccount) external {
        require(ownerOf(_tokenId) == msg.sender || _authorisedAccount == msg.sender, "Not authorised");
        _burn(_tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        
        // Ensure non-transferability by not allowing transfers after minting
        require(from == address(0), "Transfers are not allowed");
    }
}

