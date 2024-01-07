// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Immutable {
    bytes32 public immutable hash;

    constructor(uint256 number) {
        hash = keccak256(abi.encode(number));
    }
}
