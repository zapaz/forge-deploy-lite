// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {console} from "forge-std/console.sol";

contract Complex {
    uint256 public immutable num;

    constructor(uint256 a, uint8 b) {
        num = a + uint256(b);
    }
}
