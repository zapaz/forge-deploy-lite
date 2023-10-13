// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Square, SquareLib} from "../src/Square.sol";
import {DeployLite} from "../script/DeployLite.s.sol";

contract SquareTest is Test, DeployLite {
    Square public square;

    function setUp() public {
        square = new Square();
    }

    function test_Square_OK() public pure {
        assert(true);
    }

    function test_Square_addresses() public view {
        console.log(address(square), "Square address");
        console.log(address(SquareLib), "SquareLib address");
    }

    function test_Square_init() public view {
        assert(square.n() == 2);
    }

    function test_Square_pow() public {
        square.pow();
        assert(square.n() == 4);
    }
}
