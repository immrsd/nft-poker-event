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
    ROYAL_FLUSH, STRAIGHT_FLUSH, QUADS, FULL_HOUSE, FLUSH, STRAIGHT, SET, TWO_PAIRS, PAIR, NOTHING
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

library BitUtils {

    function setBit(uint256 value, uint8 position)
        pure
        internal
        returns (uint256)
    {
        uint256 result;
        assembly {
            let mask := shl(position, 1)
            result := or(value, mask)
        }
        return result;
    }

    function isBitSet(uint256 value, uint8 position)
        pure
        internal
        returns (bool)
    {
        bool result;
        assembly {
            let mask := shl(position, 1)
            result := gt(and(value, mask), 0)
        }
        return result;
    }
}

library HandUtils {

    function resolveCards(bytes32 _handSeed)
        pure
        internal
        returns (Card[5] memory)
    {

    }

    function resolveCombination(Card[5] memory _cards)
        pure
        internal
        returns (Combination)
    {
        
    }

    function encodeHand(Hand memory _hand)
        pure
        internal
        returns (uint256)
    {
        
    }
}

contract Tournament {

    // Сonstants
    uint256 immutable public ENTRANCE_FEE;
    bytes32 immutable public SEED_CHECKHASH;
    uint8 constant TO_BE_REVEALED_BIT = 255;
    
    // Storage
    address public owner;
    bool public hasStarted = false;
    bytes32 public sharedSeed;
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
        uint256 playerHash = BitUtils.setBit(rawHash, TO_BE_REVEALED_BIT);
        playerData[msg.sender] = playerHash;
    }

    function revealHand() external {
        require(hasStarted, "Tournament hasn't started yet");
        uint256 playerSeed = playerData[msg.sender];
        require(BitUtils.isBitSet(playerSeed, TO_BE_REVEALED_BIT), "Not unrolled or already revealed");
        bytes32 handSeed = keccak256(abi.encodePacked(playerSeed, sharedSeed));
        Card[5] memory cards = HandUtils.resolveCards(handSeed);
        Combination combination = HandUtils.resolveCombination(cards);
        Hand memory hand = Hand(
            combination,
            cards,
            msg.sender
        );
        playerData[msg.sender] = HandUtils.encodeHand(hand);
    }

    function start(bytes32 _seed) external {
        require(owner == msg.sender, "Only callable by owner");
        require(keccak256(abi.encode(_seed)) == SEED_CHECKHASH, "Invalid seed provided");
        sharedSeed = _seed;
        hasStarted = true;
    }
    
    function withdraw() external {
        require(owner == msg.sender, "Only callable by owner");
        require(hasStarted, "Unable to withdraw before start");
        (bool isSuccess,) = owner.call{ value: address(this).balance }("");
        require(isSuccess);
    }
}
