// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./card-entities.sol";
import { BitUtils } from "./utils/bit-utils.sol";
import { CardUtils } from "./utils/card-utils.sol";

enum Stage {
    INITIAL,
    REGISTRATION,
    RUNNING,
    FINISHED
}

struct Chipleader {
    uint16 handPower;
    address player;
    uint256 handId;
}

contract Tournament is ERC721Enumerable, Ownable {

    /* Сonstants */

    uint256 constant public TOURNAMENT_DURATION = 21 days;
    uint256 constant public MAX_ENTRIES_PER_PLAYER = 50;
    uint8 constant private TO_BE_REVEALED_BIT = 255;

    uint256 immutable public ENTRANCE_FEE;
    uint256 immutable public RAKE_PERCENTAGE;
    bytes32 immutable public SEED_CHECKHASH;
    
    /* Storage */

    bool public whitelistOnly = true;
    bool public didWithdrawRake = false;
    Stage public stage = Stage.INITIAL;
    uint48 public finishTimestamp;
    Chipleader public chipleader;
    bytes32 private merkleRoot;
    uint256 public prizeAmount;
    bytes32 public sharedSeed;
    uint256[] public allHands;

    /* Events */

    event PublicRegistrationStart();
    event TournamentStart();
    event PrizeMoneyAdded(address indexed user, uint256 addAmount, uint256 newPrizeAmount);
    event NewPlayer(address indexed player, uint256 entriesCount);
    event NewChipleader(address indexed player, uint256 indexed handId, uint16 handPower);
    event HandReveal(address indexed player, uint256 indexed handId, uint16 handPower);
    event TournamentFinish(address indexed winner, uint256 indexed handId, uint16 handPower, uint256 prizeAmount);
    event RakeWithdrawal(address owner, uint256 rakeAmount);

    /* Constructor */

    constructor(
        uint256 _ENTRANCE_FEE,
        uint256 _RAKE_PERCENTAGE,
        bytes32 _SEED_CHECKHASH,
        bytes32 _merkleRoot
    ) 
        ERC721("PokerNFT", "PKR") 
    {
        ENTRANCE_FEE = _ENTRANCE_FEE;
        RAKE_PERCENTAGE = _RAKE_PERCENTAGE;
        SEED_CHECKHASH = _SEED_CHECKHASH;
        merkleRoot = _merkleRoot;
    }

    /* Public functions */

    function enroll(uint256 _entriesCount, bytes32[] calldata _merkleProof) external payable {
        require(msg.value >= ENTRANCE_FEE * _entriesCount, "Not enough money");
        require(stage == Stage.REGISTRATION, "Registration not active");
        address player = msg.sender;
        require(isEligible(player, _merkleProof), "Whitelisted only");
        require(_entriesCount + balanceOf(player) <= MAX_ENTRIES_PER_PLAYER, "Entry limit exceeded");

        bytes32 baseHash = keccak256(abi.encodePacked(player, block.timestamp));
        uint256 totalCount = allHands.length;
        for (uint256 entryIndex = 0; entryIndex < _entriesCount; entryIndex++) {
            _registerEntry(
                player,
                baseHash, 
                entryIndex, 
                totalCount + entryIndex
            );
        }
        emit NewPlayer(player, _entriesCount);
    }

    function isEligible(address _player, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        if (whitelistOnly) {
            bool isWhitelisted = MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(_player))
            );
            return isWhitelisted;
        }
        return true;
    }

    function showdown() external {
        require(stage == Stage.RUNNING, "Not active yet");
        address player = msg.sender;
        uint256 handCount = balanceOf(player);

        for (uint256 i = 0; i < handCount; i++) {
            uint256 handId = tokenOfOwnerByIndex(player, i);
            _revealHand(player, handId);
        }
    }

    function addPrizeMoney() 
        external 
        payable
    {
        /* Allow to increase prize amount by sending ETH to contract */
        require(stage != Stage.FINISHED, "Already finished");
        require(msg.value > 0, "Nothing to add");
        emit PrizeMoneyAdded(msg.sender, msg.value, _calculatePrizeAmount());
    }

    function prizeMoney() 
        external 
        view 
        returns (uint256)
    {
        if (stage == Stage.FINISHED) {
            return prizeAmount;
        } else {
            return _calculatePrizeAmount();
        }
    }

    function withdrawPrize() external {
        require(stage == Stage.RUNNING, "Tournament is not active");
        require(uint48(block.timestamp) > finishTimestamp, "Too early");
        Chipleader memory _chipleader = chipleader;
        require(_chipleader.player == msg.sender, "You're not chipleader");

        // Update state
        uint256 _prizeAmount = _calculatePrizeAmount();
        prizeAmount = _prizeAmount;
        stage = Stage.FINISHED; // mutates state before external call

        // Transfer prize
        (bool isSuccess,) = msg.sender.call{ value: _prizeAmount }("");
        require(isSuccess);
        emit TournamentFinish(_chipleader.player, _chipleader.handId, _chipleader.handPower, _prizeAmount);
    }

    /* Owner functions */

    function updateMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyOwner
    {
        require(stage == Stage.INITIAL);
        merkleRoot = _newMerkleRoot;
    }

    function openForPublic()
        external
        onlyOwner
    {
        require(whitelistOnly, "Already opened");
        whitelistOnly = false;
        emit PublicRegistrationStart();
    }

    function letTheGameBegin(bytes32 _seed)
        external
        onlyOwner
    {
        require(keccak256(abi.encode(_seed)) == SEED_CHECKHASH, "Invalid seed");
        sharedSeed = _seed;
        stage = Stage.RUNNING;
        finishTimestamp = uint48(block.timestamp + TOURNAMENT_DURATION);
        prizeAmount = address(this).balance * (100 - RAKE_PERCENTAGE) / 100;
        emit TournamentStart();
    }
    
    function withdrawRake() 
        external
        onlyOwner
    {
        require(stage == Stage.RUNNING || stage == Stage.FINISHED, "Invalid stage");
        require(!didWithdrawRake, "Already withdrawn");
        uint256 _prizeAmount = _calculatePrizeAmount();
        uint256 rakeAmount = address(this).balance - _prizeAmount;
        didWithdrawRake = true; // mutates state before external call
        (bool isSuccess,) = owner().call{ value: rakeAmount }("");
        require(isSuccess);
        emit RakeWithdrawal(msg.sender, rakeAmount);
    }

    /* Private functions */

    function _calculatePrizeAmount() 
        private 
        view 
        returns (uint256) 
    {
        if (didWithdrawRake) {
            return address(this).balance;
        } else {
            uint256 balance = address(this).balance;
            uint256 rake = (balance * RAKE_PERCENTAGE) / 100;
            return balance - rake;
        }
    }

    function _registerEntry(
        address _player, 
        bytes32 _baseHash, 
        uint256 _entryIndex, 
        uint256 _handId
    ) private {
        uint256 handHash = uint256(keccak256(abi.encodePacked(_baseHash, _entryIndex)));
        // First bit of hand hash is used to store 'toBeRevealed' flag (to optimize storage usage and gas consumption)
        // '1' stands for "hand hasn't been revealed yet", '0' for "hand is already revealed"
        uint256 modifiedHash = BitUtils.setBit(handHash, TO_BE_REVEALED_BIT);
        allHands[_handId] = modifiedHash;
        _safeMint(_player, _handId);
    }

    function _revealHand(address _player, uint256 _handId) private {
        uint256 handSeed = allHands[_handId];
        if (BitUtils.isBitSet(handSeed, TO_BE_REVEALED_BIT)) {
            return; // Hand has already been revealed
        }
        bytes32 finalSeed = keccak256(abi.encodePacked(handSeed, sharedSeed));

        // Resolve hand
        Card[5] memory cards = CardUtils.resolveCards(finalSeed);
        (Combination combination, uint16 power) = CardUtils.resolveCombination(cards);
        Hand memory hand = Hand(
            false,
            power,
            combination,
            cards,
            _player
        );

        // Update chipleader if needed
        if (hand.power > chipleader.handPower) {
            _clearCurrentChipleaderStatus();
            hand.isChipleader = true;
            // Hand power and chipleader's address are stored in single storage slot
            // We optimize gas consumption, saving brand new struct instead of updating each property
            chipleader = Chipleader(hand.power, _player, _handId);
            emit NewChipleader(_player, _handId, hand.power);
        }

        allHands[_handId] = CardUtils.encodeHand(hand);
        emit HandReveal(_player, _handId, hand.power);
    }

    function _clearCurrentChipleaderStatus() private {
        if (chipleader.player == address(0)) {
            return;
        }
        uint256 id = chipleader.handId;
        uint256 data = allHands[id];
        Hand memory hand = CardUtils.decodeHand(data);
        hand.isChipleader = false;
        allHands[id] = CardUtils.encodeHand(hand);
    }
}
