// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {console} from "forge-std/console.sol";

import {DeployCounter} from "./deploy/DeployCounter.s.sol";
import {DeployImmutable} from "./deploy/DeployImmutable.s.sol";
import {DeployComplex} from "./deploy/DeployComplex.s.sol";

contract DeployAll is DeployCounter, DeployImmutable, DeployComplex {
    function run() public override(DeployCounter, DeployImmutable, DeployComplex) {
        console.log("chainId %s  msg.sender @%s", block.chainid, msg.sender);

        deployCounter();
        deployImmutable();
        deployComplex();
    }
}
