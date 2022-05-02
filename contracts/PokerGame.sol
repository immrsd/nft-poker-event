// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum Rank {
    TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN, JACK, QUEEN, KING, ACE
}

enum Suit {
    CLUBS, SPADES, DIAMONDS, HEARTS 
}

enum Rarity {
    LEGENDARY, EPIC, RARE, COMMON
}

enum Combination {
    ROYAL_FLUSH, STRAIGHT_FLUSH, QUADS, FULL_HOUSE, FLUSH, STRAIGHT, SET, TWO_PAIRS, PAIR, UNDEFINED
}

struct Card {
    Rarity rarity;
    Rank rank;
    Suit suit;
}

struct Hand {
    Combination combination;
    Card[5] cards;
    address owner;
}

contract Tournament {

    // constants
    uint256 immutable public ENTRANCE_FEE;
    bytes32 immutable public SEED_CHECKHASH;
    
    // storage
    address public owner;
    bool public isRevealed = false;
    bytes32 public seed;
    mapping(address => uint256) public playerData;

    constructor(
        uint256 _ENTRANCE_FEE,
        bytes32 _SEED_CHECKHASH
    ) {
        ENTRANCE_FEE = _ENTRANCE_FEE;
        SEED_CHECKHASH = _SEED_CHECKHASH;
    }

    function enrollInTournament() 
        external
        payable
    {
        require(playerData[msg.sender] == 0, "Already enrolled");
        require(msg.value >= ENTRANCE_FEE, "Not enough money");
        uint256 rawHash = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
        uint256 playerHash = rawHash & (1 << 255);
        playerData[msg.sender] = playerHash;
    }

    function reveal(bytes32 _seed) external {
        require(owner == msg.sender, "Only callable by owner");
        require(keccak256(abi.encode(_seed)) == SEED_CHECKHASH, "Invalid seed provided");
        seed = _seed;
        isRevealed = true;
    }
    
    function withdraw() external {
        require(owner == msg.sender, "Only callable by owner");
        require(isRevealed, "Unable to withdraw before reveal");
        (bool isSuccess,) = owner.call{ value: address(this).balance }("");
        require(isSuccess);
    }
}
