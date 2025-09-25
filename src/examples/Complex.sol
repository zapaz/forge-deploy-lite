// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Complex {
    uint256 public immutable NUM;

    constructor(uint256 a, uint8 b) {
        NUM = a + uint256(b);
    }
}
