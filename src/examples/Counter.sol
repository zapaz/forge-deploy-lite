// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint256 public number;

    constructor(uint256 newNumber) {
        number = newNumber << 1;
    }

    function increment() public {
        number++;
    }
}
