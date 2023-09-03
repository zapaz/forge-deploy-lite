// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// same contract but with different comments
contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
