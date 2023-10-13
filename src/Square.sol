// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SquareLib} from "./SquareLib.sol";

contract Square {
    using SquareLib for uint256;

    uint256 public n = 2;

    function pow() public {
        n = n.square();
    }
}
