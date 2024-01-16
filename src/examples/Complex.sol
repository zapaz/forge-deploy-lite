// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Complex {
    address constant anvil8 = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
    uint256 immutable num;

    constructor(uint256 a, uint8 b) {
        require(msg.sender == anvil8, "not anvil8!");
        num = a + uint256(b);
    }
}
