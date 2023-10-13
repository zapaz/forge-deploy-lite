// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../script/DeployLite.s.sol";
import {Square} from "../src/Square.sol";
import {SquareLib} from "../src/SquareLib.sol";

import {console} from "forge-std/console.sol";

contract DeploySquare is DeployLite {
    function deploySquare() public returns (address square) {
        console.log("deploySquare ~ squareLib:", address(SquareLib));

        // vm.broadcast();
        // square = address(new Square());
    }

    function run() public virtual {
        // console.log("deploySquare ~ squareLib:", address(SquareLib), address(SquareLib).code.length);
        // console.logBytes(address(SquareLib).code);
        setRecording(false);
        deploy("Square");
    }
}
