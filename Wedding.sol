// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "WeddingCertificate.sol";

contract WeddingContract {
    struct Engagement {
        address partner1;
        address partner2;
        uint256 weddingDate;
        bool isEngaged;
        bool isMarried;
        GuestList guestList;
        uint256 certificateIdP1;
        uint256 certificateIdP2;
        bool divorceVote1;
        bool divorceVote2;
        bool divorceVote3;
    }

    struct SensitiveInformation {
        GuestList guestList;
        string phoneNumber1;
        string phoneNumber2;
        // etc.
    }

    struct GuestList {
        address[] guests;
        bool[] votes;
        bool partner1Confirmed;
        bool partner2Confirmed;
    }

    mapping(address => address) public preferences;

    //mapping(address => string) public publicKeys;
    //mapping(address => string) private privateKeys;

    mapping(address => bytes32) public userToKey;
    mapping(bytes32 => Engagement) public engagements;    

    WeddingCertificate private weddingCertificate;
    uint256 private nextCertificateId = 1; // TODO mutex lock

    address[] private authorizedAddresses = [
        0xdD870fA1b7C4700F2BD7f44238821C26f7392148,
        0x583031D1113aD414F02576BD6afaBfb302140225,
        0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB,
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    ];

    constructor() {
        weddingCertificate = new WeddingCertificate();
    }

    // Generate a unique key for the engagement mapping
    function generateEngagementKey(address p1, address p2)
        private pure returns (bytes32)
    {
        address first = p1 < p2 ? p1 : p2;
        address second = p1 > p2 ? p1 : p2;
        return keccak256(abi.encodePacked(first, second));
    }

    function cleanupEngagementObject(Engagement storage engagement)
        private
    {
        // Remove key from userToKey
        userToKey[engagement.partner1] = bytes32(0);
        userToKey[engagement.partner2] = bytes32(0);

        // Revoke the wedding
        engagement.partner1 = address(0);
        engagement.partner2 = address(0);
        engagement.weddingDate = 0;
        engagement.isEngaged = false;
        engagement.isMarried = false;
        engagement.guestList.partner1Confirmed = false;
        engagement.guestList.partner2Confirmed = false;

        // Reset guest list
        delete engagement.guestList.guests;
    }

    //////// Modifiers ////////
    // Check if user is not yet engaged
    modifier notAlreadyEngaged(address user) {
        require(!engagements[userToKey[user]].isEngaged, "User is already engaged");
        _;
    }

    // Check if a user is already engaged
    modifier isEngaged(address user) {
        require(engagements[userToKey[user]].isEngaged, "User is not yet engaged");
        _;
    }

    // Check if user is not yet married
    modifier notAlreadyMarried(address user) {
        require(!engagements[userToKey[user]].isMarried, "User is already married");
        _;
    }

    // Check if a user is already engaged
    modifier isMarried(address user) {
        require(engagements[userToKey[user]].isMarried, "User is not yet married");
        _;
    }

    // Check if wedding date is in the future
    modifier validWeddingDate(uint256 weddingDate) {
        require(weddingDate > block.timestamp, "Wedding date must be in the future");
        _;
    }

    // Check if both parties confirmed the guestlist
    modifier guestListConfirmed(address user) {
        Engagement memory engagement = engagements[userToKey[user]];
        require(engagement.guestList.partner1Confirmed && engagement.guestList.partner2Confirmed, "Guest list not yet confirmed by both");
        _;
    }

    // Check if one of the parties hasn't confirmed the guestlist yet
    modifier guestListUnconfirmed(address user) {
        Engagement memory engagement = engagements[userToKey[user]];
        require(!engagement.guestList.partner1Confirmed || !engagement.guestList.partner2Confirmed, "Guest list already confirmed by both");
        _;
    }

    // Check if the current time is before the wedding day
    modifier beforeWeddingDay(address user) {
        Engagement memory engagement = engagements[userToKey[user]];
        uint256 startOfWeddingDay = engagement.weddingDate - (engagement.weddingDate % 1 days);

        require(
            block.timestamp <= startOfWeddingDay,
            "Action not allowed after the start of the wedding day"
        );
        _;
    }

    // Check if the current time is during the wedding day
    modifier duringWeddingDay(address user) {
        Engagement memory engagement = engagements[userToKey[user]];
        
        uint256  startOfWeddingDay = engagement.weddingDate - (engagement.weddingDate % 1 days);
        uint256 endOfWeddingDay = startOfWeddingDay + 1 days;

        require(
            block.timestamp >= startOfWeddingDay && block.timestamp < endOfWeddingDay,
            "Action is only allowed during the wedding day"
        );

        _;
    }

    //////// 1. Engagement ////////
    // Engage two users
    function engage(address partner, uint256 weddingDate) 
        public 
        notAlreadyEngaged(msg.sender) 
        notAlreadyEngaged(partner) 
        notAlreadyMarried(msg.sender) 
        notAlreadyMarried(partner) 
        validWeddingDate(weddingDate) 
    {
        require(msg.sender != partner, "You can't engage yourself");

        // Set my engagement-preference to my partner
        preferences[msg.sender] = partner;

        // Check if my partner also has me as an engagement-preference
        // if so, we officially get engaged
        if (preferences[partner] == msg.sender) {
            // Generate the common key
            bytes32 key = generateEngagementKey(msg.sender, partner);
            userToKey[msg.sender] = key;
            userToKey[partner] = key;
            
            engagements[key] = Engagement({
                partner1: msg.sender, 
                partner2: partner, 
                weddingDate: weddingDate,
                isEngaged: true,
                isMarried: false, 
                guestList: GuestList({
                    guests: new address[](0),
                    votes: new bool[](0),
                    partner1Confirmed: false,
                    partner2Confirmed: false
                }),
                certificateIdP1: 0,
                certificateIdP2: 0,
                divorceVote1: false,
                divorceVote2: false,
                divorceVote3: false
            });

            // Set preferences to 0, as we'll use this later for the marriage voting
            preferences[msg.sender] = address(0);
            preferences[partner] = address(0);
        }
    }

    // Change the wedding date of your engagement
    function changeWeddingDate(uint256 weddingDate)
        public
        notAlreadyEngaged(msg.sender)
    {
        Engagement storage engagement = engagements[userToKey[msg.sender]];
        // Don't change if not necesarry
        if (engagement.weddingDate != weddingDate) {
            engagement.weddingDate = weddingDate;
        }
    }
    
    // Function mainly for debugging purposes
    function getEngagementDetails(address user) 
        public isEngaged(user) view returns (Engagement memory)
    {
        bytes32 key = userToKey[user];
        return engagements[key];
    }

    //////// 2. Participations ////////
    // TODO do we actually need to send out participations after the list is confirmed??
    // |-> maybe in the form of an NFT??
    // Function to propose a guest list by one of the partners
    function proposeGuestList(address[] memory guests) 
        public isEngaged(msg.sender) guestListUnconfirmed(msg.sender) 
    {
        Engagement storage engagement = engagements[userToKey[msg.sender]];

        // Check if the sender is one of the partners, to be sure
        if (engagement.partner1 == msg.sender || engagement.partner2 == msg.sender) {
            // Make sure that both partners are not in the guest list
            bool isInGuestList = false;
            for (uint i = 0; i < guests.length; i++) {
                if (guests[i] == engagement.partner1 || guests[i] == engagement.partner2) {
                    isInGuestList = true;
                    break;
                }
            }

            require(!isInGuestList, "One of the partners is in the guest list");

            engagement.guestList.guests = guests;
            engagement.guestList.votes = new bool[](guests.length);

            // List changed, so reset confirmations
            engagement.guestList.partner1Confirmed = false;
            engagement.guestList.partner2Confirmed = false;
        }
    }

    // Function for a partner to confirm the guest list
    function confirmGuestList() 
        public isEngaged(msg.sender)
    {
        Engagement storage engagement = engagements[userToKey[msg.sender]];

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
        Engagement memory engagement = engagements[userToKey[user]];

        return engagement.guestList.guests;
    }

    //////// 3. Revoke engagement ////////
    // Function to revoke the engagement
    function revokeEngagement() 
        public 
        isEngaged(msg.sender) 
        beforeWeddingDay(msg.sender) 
        notAlreadyMarried(msg.sender)
    {
        bytes32 key = userToKey[msg.sender];
        Engagement storage engagement = engagements[key];

        // Check if the sender is one of the partners
        require(
            engagement.partner1 == msg.sender || engagement.partner2 == msg.sender,
            "Caller is not part of this engagement"
        );
        
        // Cleanup
        cleanupEngagementObject(engagement);
    }

    //////// 4. Wedding ////////
    // TODO: What if they haven't said yes on the wedding date ??
    // |-> Do we need to discard the wedding somehow (clear the engagement)??
    function marry(address partner)
        public 
        isEngaged(msg.sender) 
        isEngaged(partner)
        notAlreadyMarried(msg.sender)
        notAlreadyMarried(partner)
        duringWeddingDay(msg.sender)
    {
        // Check that you're trying to marry the person you're engaged with
        Engagement memory check_engagement = engagements[userToKey[msg.sender]];
        if (check_engagement.partner1 == msg.sender) {
            require(check_engagement.partner2 == partner, "You have to be engaged to the person you want to marry");
        } else {
            require(check_engagement.partner1 == partner, "You have to be engaged to the person you want to marry");
        }

        // "Say yes" to my partner
        preferences[msg.sender] = partner;

        // If my partner already said "yes", we get married
        if (preferences[partner] == msg.sender) {
            Engagement storage engagement = engagements[userToKey[msg.sender]];
            engagement.isMarried = true;

            // If the guest list was unconfirmed, we set it to empty (don't store it)
            if (!engagement.guestList.partner1Confirmed || !engagement.guestList.partner2Confirmed) {
                delete engagement.guestList;
            }

            // Reset preferences in case we need it later
            preferences[msg.sender] = address(0);
            preferences[partner] = address(0);

            // Give both a WeddingCertificate
            uint256 certificateId1 = nextCertificateId++;
            uint256 certificateId2 = nextCertificateId++;
    
            weddingCertificate.mintCertificate(msg.sender, certificateId1);
            weddingCertificate.mintCertificate(partner, certificateId2);

            // store certificateId
            engagement.certificateIdP1 = certificateId1;
            engagement.certificateIdP2 = certificateId2;
        }
    }

    function divorce(address partner)
        public
        isMarried(partner)
    {
        // Check if it's an authorized account
        bool isAuthorizedAddress = false;
        for (uint i = 0; i < authorizedAddresses.length; i++) {
            if (authorizedAddresses[i] == msg.sender) {
                isAuthorizedAddress = true;
                break;
            }
        }

        // Check that you're trying to marry the person you're engaged with
        Engagement storage engagement = engagements[userToKey[partner]];
        if (engagement.partner1 == msg.sender) {
            require(engagement.partner2 == partner, "You have to be married to the person you want to divorce");
            engagement.divorceVote1 = true;
        } else if (engagement.partner2 == msg.sender) {
            require(engagement.partner1 == partner, "You have to be married to the person you want to divorce");
            engagement.divorceVote2 = true;
        } else if (isAuthorizedAddress) {
            engagement.divorceVote3 = true;
        }

        // Count number of divorce votes
        uint count = 0;
        if (engagement.divorceVote1) count++;
        if (engagement.divorceVote2) count++;
        if (engagement.divorceVote3) count++;

        if (count >= 2) {
            // Burn both certificates
            weddingCertificate.burnCertificate(engagement.certificateIdP1);
            weddingCertificate.burnCertificate(engagement.certificateIdP2);

            // Cleanup
            cleanupEngagementObject(engagement);
        }
    }

    //////// 5. Voting ////////
    function voteAgainstWedding(address partner)
        public
        isEngaged(partner)
        notAlreadyMarried(partner)
        duringWeddingDay(partner)
        guestListConfirmed(partner)
    {
        Engagement storage engagement = engagements[userToKey[partner]];
        
        uint voteCount = 0;
        // Check if the you're part of the confirmed guest list 
        // and count votes at the same time
        for (uint i = 0; i < engagement.guestList.guests.length; i++) 
        {
            // guest, so cast vote
            if (engagement.guestList.guests[i] == msg.sender) {
                engagement.guestList.votes[i] = true;
            }
            // count vote
            if (engagement.guestList.votes[i]) {
                voteCount++;
            }
        }

        // If more than half vote in favor, disband engagement
        // (not the marriage as they didn't get married yet)
        if (voteCount > engagement.guestList.guests.length / 2) {
            cleanupEngagementObject(engagement);
        }
    }
}