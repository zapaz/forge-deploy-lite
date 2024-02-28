// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Immutable {
    bytes32 public immutable hash;
    uint8 public immutable p;

    constructor(uint256 a, uint8 b) {
        hash = keccak256(abi.encode(a));
        p = b << 1;
    }
}
