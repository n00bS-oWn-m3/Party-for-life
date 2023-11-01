// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WeddingCertificate.sol"; // Assuming WeddingCertificate contract is in the same directory

contract Wedding {

    struct Couple {
        address fiance1;
        address fiance2;
        uint256 weddingDate;
        bool isEngaged;
        bool isMarried;
        address[] guestList;
        uint256 negativeVotes;
    }

    mapping(address => Couple) public engagements;
    mapping(address => bool) public authorisedAccounts;
    address public weddingCertificateAddress;

    modifier notEngaged(address fiance) {
        require(engagements[fiance].fiance1 == address(0) && engagements[fiance].fiance2 == address(0), "Fiance is already engaged");
        //check if previus line is correct also if fiance is not in the engagement dictionary
        _;
    }

    constructor(address _weddingCertificateAddress) {
        weddingCertificateAddress = _weddingCertificateAddress;
    }

    function engage(address _fiance, uint256 _weddingDate) external notEngaged(msg.sender) notEngaged(_fiance) {
        //check if is still works if one send before the other because maybe the other result engaged
        //also add for the other fiance
        engagements[msg.sender] = Couple({
            fiance1: msg.sender,
            fiance2: _fiance,
            weddingDate: _weddingDate,
            isEngaged: true,
            isMarried: false,
            guestList: new address[](0),
            negativeVotes: 0
        });
    }

    function confirmGuestList(address[] calldata _guestList) external {
        require(engagements[msg.sender].isEngaged, "Not engaged");
        engagements[msg.sender].guestList = _guestList;
    }

    function revokeEngagement() external {
        require(engagements[msg.sender].isEngaged, "Not engaged");
        delete engagements[msg.sender];
    }

    function marry() external {
        require(engagements[msg.sender].isEngaged, "Not engaged");
        require(block.timestamp <= engagements[msg.sender].weddingDate, "Not the wedding day");
        engagements[msg.sender].isMarried = true;
        
        // Issue wedding certificate NFT
        WeddingCertificate(weddingCertificateAddress).mint(engagements[msg.sender].fiance1, engagements[msg.sender].fiance2);
    }

    function voteAgainstWedding() external {
        require(engagements[msg.sender].isEngaged, "Not engaged");
        for(uint256 i = 0; i < engagements[msg.sender].guestList.length; i++) {
            if(engagements[msg.sender].guestList[i] == msg.sender) {
                engagements[msg.sender].negativeVotes++;
                break;
            }
        }

        if(engagements[msg.sender].negativeVotes > engagements[msg.sender].guestList.length / 2) {
            engagements[msg.sender].isEngaged = false;
        }
    }

    function addAuthorisedAccount(address _account) external {
        authorisedAccounts[_account] = true;
    }

    function removeAuthorisedAccount(address _account) external {
        authorisedAccounts[_account] = false;
    }
}

