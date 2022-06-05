// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Rank {
    TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN, JACK, QUEEN, KING, ACE
}

enum Suit {
    CLUBS, SPADES, DIAMONDS, HEARTS 
}

enum Combination {
    ROYAL_FLUSH, STRAIGHT_FLUSH, QUADS, FULL_HOUSE, FLUSH, STRAIGHT, SET, TWO_PAIRS, PAIR, NOTHING
}

struct Card {
    Rank rank;
    Suit suit;
}

struct Hand {
    bool isChipleader;
    uint16 power;
    Combination combination;
    Card[5] cards;
    address owner;
}
