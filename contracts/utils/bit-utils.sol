// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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