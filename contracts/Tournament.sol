// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

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
    uint16 power;
    Combination combination;
    Card[5] cards;
    address owner;
}

struct FirstPlace {
    uint16 handPower;
    address leader;
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
        /* To be implemented */
    }

    function resolveCombination(Card[5] memory _cards)
        pure
        internal
        returns (Combination combination, uint16 power)
    {
        /* To be implemented */
    }

    function encodeHand(Hand memory _hand)
        pure
        internal
        returns (uint256)
    {
        /* To be implemented */
    }
}

contract Tournament is Ownable {

    // Сonstants
    uint256 immutable public ENTRANCE_FEE;
    uint256 immutable public RAKE_PERCENTAGE;
    bytes32 immutable public SEED_CHECKHASH;
    uint256 constant public TOURNAMENT_DURATION = 21 days;
    uint8 constant TO_BE_REVEALED_BIT = 255;
    
    // Storage
    bool public hasStarted = false;
    bool public didWithdrawRake = false;
    uint48 public finishTimestamp;
    FirstPlace public firstPlace;
    bytes32 public sharedSeed;
    mapping(address => uint256) public playerData;

    constructor(
        uint256 _ENTRANCE_FEE,
        uint256 _RAKE_PERCENTAGE,
        bytes32 _SEED_CHECKHASH
    ) {
        ENTRANCE_FEE = _ENTRANCE_FEE;
        RAKE_PERCENTAGE = _RAKE_PERCENTAGE;
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

        // Resolve hand
        Card[5] memory cards = HandUtils.resolveCards(handSeed);
        (Combination combination, uint16 power) = HandUtils.resolveCombination(cards);
        Hand memory hand = Hand(
            power,
            combination,
            cards,
            msg.sender
        );
        playerData[msg.sender] = HandUtils.encodeHand(hand);

        // Update first place if needed
        if (hand.power > firstPlace.handPower) {
            firstPlace.handPower = hand.power;
            firstPlace.leader = msg.sender;
        }
    }

    function withdrawPrize() external {
        require(hasStarted, "Unable to withdraw before start");
        require(uint48(block.timestamp) > finishTimestamp, "Too early");
        require(firstPlace.leader == msg.sender, "Caller is not tournament leader");

    }

    function letTheGameBegin(bytes32 _seed)
        external
        onlyOwner
    {
        require(keccak256(abi.encode(_seed)) == SEED_CHECKHASH, "Invalid seed provided");
        sharedSeed = _seed;
        hasStarted = true;
        finishTimestamp = uint48(block.timestamp + TOURNAMENT_DURATION);
    }
    
    function withdrawRake() 
        external
        onlyOwner
    {
        require(hasStarted, "Unable to withdraw before start");
        require(!didWithdrawRake, "Already withdrawn");
        didWithdrawRake = true;
        uint256 rakeAmount = address(this).balance * RAKE_PERCENTAGE / 100;
        (bool isSuccess,) = owner().call{ value: rakeAmount }("");
        require(isSuccess);
    }
}
