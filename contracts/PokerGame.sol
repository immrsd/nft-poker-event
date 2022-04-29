// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum Rank {
    TWO,
    THREE,
    FOUR,
    FIVE,
    SIX,
    SEVEN,
    EIGHT,
    NINE,
    TEN,
    JACK,
    QUEEN,
    KING,
    ACE
}

enum Suit {
    CLUBS,
    SPADES,
    DIAMONDS,
    HEARTS 
}

struct Card {
    Rank rank;
    Suit suit;
}

struct Hand {
    bool isDead;
    Card card1;
    Card card2;
    Card card3;
    Card card4;
    Card card5;
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

contract PokerGame {

    Hand[] public hands;
    uint256 public totalHands;
    mapping(uint256 => address) public handOwners;
    
    function combine(uint256 _upgradeHand, uint256 _sourceHand) external {

    }
}
