// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Immutable {
    bytes32 public immutable HASH;
    uint8 public immutable p;

    constructor(uint256 a, uint8 b) {
        HASH = keccak256(abi.encode(a));
        p = b << 1;
    }
}
