// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../script/DeployLite.s.sol";
import {Counter} from "../src/Counter.sol";

// import {console} from "forge-std/console.sol";

contract DeployCounter is DeployLite {
    function deployCounter() public returns (address counter) {
        DeployState state = deployState("Counter");

        if (state == DeployState.None) {
            vm.startBroadcast();

            counter = deploy("Counter");

            // ...
            // put here additional code to intialize your deployed contract
            // ...

            vm.stopBroadcast();
        }
    }

    function run() public virtual {
        deployCounter();
    }
}
