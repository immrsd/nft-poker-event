// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// enum Rank {
//     TWO,
//     THREE,
//     FOUR,
//     FIVE,
//     SIX,
//     SEVEN,
//     EIGHT,
//     NINE,
//     TEN,
//     JACK,
//     QUEEN,
//     KING,
//     ACE
// }

// enum Suit {
//     CLUBS,
//     SPADES,
//     DIAMONDS,
//     HEARTS 
// }

library BitChecker {

    function isBitSet(uint256 value, uint8 position)
        external
        pure
        returns (bool)
    {
        bool result;
        assembly {}
        uint256 mask = 1 << 
    }

}

struct Hand {
    bool isDead;
    uint8[5] cards;
    bool isRoyalFlush;
    bool isFirstRoyalFlush;
    bool isQuads;
    bool isFirstQuads;
    bool isFullHouse;
    bool isFirstFullHouse;
    bool isFlush;
    bool isFirstFlush;
    bool isStraight;
    bool isFirstStraight;
}

contract Tournament {

    Hand[] public hands;
    uint256 public totalHands;
    mapping(uint256 => address) public handOwners;
    mapping(address => uint256) public drawsByAddress;
    uint256 public ENTRANCE_FEE;
    uint256 public MAX_ENTRIES_PER_USER;
    /*
    1. users enroll
    2. owner reveals secret
    3. users relveal hands
    4. 


    */

    function enroll(uint256 entriesCount) 
        external
        payable 
    {
        require(drawsByAddress[msg.sender] == 0, "Address already enrolled");
        require(msg.value >= ENTRANCE_FEE * entriesCount);
        require(entriesCount <= MAX_ENTRIES_PER_USER);
        drawsByAddress[msg.sender] = entriesCount;
    }
    
    function combine(
        Hand storage _handToChange, 
        Hand storage _sourceHand, 
        uint256 _indexToBeChanged, 
        uint256 _sourceIndex
    ) private {
        require(_indexToBeChanged < 5 && _sourceIndex < 5, "Invalid card index");
        Card storage inCard = _sourceHand.cards[_sourceIndex];
        for(uint256 i = 0; i < 5; i++) {
            require(_handToChange.cards[i] != inCard);
        }
    }
}
