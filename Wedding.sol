// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract WeddingContract {
    struct Engagement {
        address parner1;
        address partner2;
        uint256 weddingDate;
        bool isEngaged;
        bool isMarried;
    }

    mapping(address => Engagement) public engagements;

    // Modifiers
    // Check if user is not yet engaged
    modifier notAlreadyEngaged(address user) {
        require(!engagements[user].isEngaged, "User is already engaged");
        _;
    }

    // Check if a user is already engaged
    modifier isEngaged(address user) {
        require(engagements[user].isEngaged, "User is not yet engaged");
        _;
    }

    // Check if user is not yet married
    modifier notAlreadyMarried(address user) {
        require(!engagements[user].isMarried, "User is already married");
        _;
    }

    // Check if a user is already engaged
    modifier isMarried(address user) {
        require(engagements[user].isMarried, "User is not yet married");
        _;
    }

    // Check if wedding date is in the future
    modifier validWeddingDate(uint256 weddingDate) {
        require(weddingDate > block.timestamp, "Wedding date must be in the future");
        _;
    }

    // Engage two users
    function engage(address p1, address p2, uint256 weddingDate) 
        public 
        notAlreadyEngaged(p1) 
        notAlreadyEngaged(p2) 
        notAlreadyMarried(p1) 
        notAlreadyMarried(p2) 
        validWeddingDate(weddingDate) 
    {
        engagements[p1] = Engagement(p1, p2, weddingDate, true, false);
        engagements[p2] = Engagement(p1, p2, weddingDate, true, false);
    }

    function getEngagementDetails(address user) 
        public view isEngaged(user) returns (Engagement memory)
    {
        return engagements[user];
    }
}