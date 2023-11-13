// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract WeddingContract {
    struct Engagement {
        address partner1;
        address partner2;
        uint256 weddingDate;
        bool isEngaged;
        bool isMarried;
        GuestList guestList;
    }

    struct GuestList {
        address[] guests;
        bool partner1Confirmed;
        bool partner2Confirmed;
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

    // Check if both parties confirmed the guestlist
    modifier guestListConfirmed(address user) {
        Engagement memory engagement = engagements[user];
        require(engagement.guestList.partner1Confirmed && engagement.guestList.partner2Confirmed, "Guest list not yet confirmed by both");
        _;
    }

    modifier guestListUnconfirmed(address user) {
        Engagement memory engagement = engagements[user];
        require(!engagement.guestList.partner1Confirmed || !engagement.guestList.partner2Confirmed, "Guest list already confirmed by both");
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
        GuestList memory guestList = GuestList({
            guests: new address[](0),
            partner1Confirmed: false,
            partner2Confirmed: false
        });
        
        engagements[p1] = Engagement(p1, p2, weddingDate, true, false, guestList);
        engagements[p2] = Engagement(p1, p2, weddingDate, true, false, guestList);
    }

    function getEngagementDetails(address user) 
        public view isEngaged(user) returns (Engagement memory)
    {
        return engagements[user];
    }

    // Function to propose a guest list by one of the partners
    function proposeGuestList(address[] memory guests) 
        public isEngaged(msg.sender) guestListUnconfirmed(msg.sender) 
    {
        Engagement storage engagement = engagements[msg.sender];
        
        // Check if the sender is one of the partners, to be sure
        if (engagement.partner1 == msg.sender || engagement.partner2 == msg.sender) {
            engagement.guestList.guests = guests;

            // List changed, so reset confirmations
            engagement.guestList.partner1Confirmed = false;
            engagement.guestList.partner2Confirmed = false;
        }
    }

    // Function for a partner to confirm the guest list
    function confirmGuestList() 
        public isEngaged(msg.sender)
    {
        Engagement storage engagement = engagements[msg.sender];

        // Check if the sender is one of the partners
        if (engagement.partner1 == msg.sender) {
            engagement.guestList.partner1Confirmed = true;
        } else if (engagement.partner2 == msg.sender) {
            engagement.guestList.partner2Confirmed = true;
        }
    }

    // Function to retrieve the confirmed guest list
    function getConfirmedGuestList(address user) 
        public guestListConfirmed(user) view returns (address[] memory) 
    {
        Engagement memory engagement = engagements[user];

        return engagement.guestList.guests;
    }
}