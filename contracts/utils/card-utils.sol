// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../card-entities.sol";

library CardUtils {

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