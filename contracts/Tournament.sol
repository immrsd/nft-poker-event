// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

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

struct Chipleader {
    address addr;
    uint16 handPower;
    uint256 handId;
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

    function nullifyBit(uint256 value, uint8 position)
        pure
        internal
        returns (uint256)
    {
        uint256 result;
        assembly {
            let mask := not(shl(position, 1))
            result := and(value, mask)
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

    function decodeHand(uint256 _data)
        pure
        internal
        returns (Hand memory _hand)
    {
        /* To be implemented */
    }
}

contract Tournament is ERC721Enumerable, Ownable {

    /* Сonstants */

    uint256 constant public TOURNAMENT_DURATION = 21 days;
    uint256 constant public MAX_ENTRIES_PER_PLAYER = 20;
    uint8 constant TO_BE_REVEALED_BIT = 255;

    uint256 immutable public ENTRANCE_FEE;
    uint256 immutable public RAKE_PERCENTAGE;
    bytes32 immutable public SEED_CHECKHASH;
    
    /* Storage */

    bool public hasStarted = false;
    bool public hasFinished = false;
    uint48 public finishTimestamp;
    Chipleader public chipleader;
    uint256 public prizeAmount;
    bytes32 public sharedSeed;
    uint256[] public allHands;

    /* Constructor */

    constructor(
        uint256 _ENTRANCE_FEE,
        uint256 _RAKE_PERCENTAGE,
        bytes32 _SEED_CHECKHASH
    ) 
        ERC721("PokerNFT", "PKR") 
    {
        ENTRANCE_FEE = _ENTRANCE_FEE;
        RAKE_PERCENTAGE = _RAKE_PERCENTAGE;
        SEED_CHECKHASH = _SEED_CHECKHASH;
    }

    /* Public functions */

    function enroll(uint256 _entriesCount) external payable {
        require(_entriesCount <= MAX_ENTRIES_PER_PLAYER);
        require(!hasStarted, "Tournament already started");
        require(msg.value >= ENTRANCE_FEE * _entriesCount, "Not enough money");

        bytes32 playerHash = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        uint256 totalCount = allHands.length;
        for (uint256 entryIndex = 0; entryIndex < _entriesCount; entryIndex++) {
            _registerEntry(
                playerHash, 
                entryIndex, 
                totalCount + entryIndex
            );
        }
    }

    function showdown() external isActive {
        address player = msg.sender;
        uint256 handCount = balanceOf(player);

        for (uint256 i = 0; i < handCount; i++) {
            uint256 handId = tokenOfOwnerByIndex(player, i);
            _revealHand(handId);
        }
    }

    function addPrizeMoney() 
        external 
        payable
    {
        require(!hasFinished, "Tournament already finished");
        /* Allow increasing prize amount by sending ETH to contract */
    }

    function currentPrizePool() 
        external 
        view 
        returns (uint256)
    {
        if (hasStarted) {
            return prizeAmount;
        } else {
            return address(this).balance * (100 - RAKE_PERCENTAGE) / 100;
        }
    }

    function withdrawPrize() 
        external
        isActive
    {
        require(uint48(block.timestamp) > finishTimestamp, "Too early");
        require(chipleader.addr == msg.sender, "Caller is not tournament chipleader");

        // Update state
        hasFinished = true;
        prizeAmount = 0;

        // Transfer prize
        (bool isSuccess,) = msg.sender.call{ value: prizeAmount }("");
        require(isSuccess);
    }

    /* Owner functions */

    function letTheGameBegin(bytes32 _seed)
        external
        onlyOwner
    {
        require(keccak256(abi.encode(_seed)) == SEED_CHECKHASH, "Invalid seed provided");
        sharedSeed = _seed;
        hasStarted = true;
        finishTimestamp = uint48(block.timestamp + TOURNAMENT_DURATION);
        prizeAmount = address(this).balance * (100 - RAKE_PERCENTAGE) / 100;
    }
    
    function withdrawRake() 
        external
        onlyOwner
    {
        require(hasStarted, "Unable to withdraw before start");
        uint256 rakeAmount = address(this).balance - prizeAmount;
        (bool isSuccess,) = owner().call{ value: rakeAmount }("");
        require(isSuccess);
    }

    /* Private functions */

    function _registerEntry(bytes32 _playerHash, uint256 _entryIndex, uint256 _handId) private {
        uint256 handHash = uint256(keccak256(abi.encodePacked(_playerHash, _entryIndex)));
        uint256 modifiedHash = BitUtils.setBit(handHash, TO_BE_REVEALED_BIT);
        allHands[_handId] = modifiedHash;
        _safeMint(msg.sender, _handId);
    }

    function _revealHand(uint256 _handId) private {
        uint256 handSeed = allHands[_handId];
        if (BitUtils.isBitSet(handSeed, TO_BE_REVEALED_BIT)) {
            return; // Hand has been already revealed
        }
        bytes32 finalSeed = keccak256(abi.encodePacked(handSeed, sharedSeed));

        // Resolve hand
        Card[5] memory cards = HandUtils.resolveCards(finalSeed);
        (Combination combination, uint16 power) = HandUtils.resolveCombination(cards);
        Hand memory hand = Hand(
            false,
            power,
            combination,
            cards,
            msg.sender
        );

        // Update chipleader if needed
        if (hand.power > chipleader.handPower) {
            _clearCurrentChipleaderStatus();
            hand.isChipleader = true;
            chipleader = Chipleader(msg.sender, hand.power, _handId);
        }

        allHands[_handId] = HandUtils.encodeHand(hand);
    }

    function _clearCurrentChipleaderStatus() private {
        if (chipleader.addr == address(0)) {
            return;
        }
        uint256 id = chipleader.handId;
        uint256 data = allHands[id];
        Hand memory hand = HandUtils.decodeHand(data);
        hand.isChipleader = false;
        allHands[id] = HandUtils.encodeHand(hand);
    }

    /* Modifiers */

    modifier isActive() {
        require(hasStarted && !hasFinished, "Tournament not active");
        _;
    }
}
