// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {DeployLite} from "script/DeployLite.sol";
import {Counter} from "src/Counter.sol";

contract DeployCounter is DeployLite {
    function deployCounter() public returns (address counter) {
        vm.startBroadcast();

        counter = address(new Counter());

        vm.stopBroadcast();
    }

    function run() public virtual {
        deploy("Counter");
    }
}
