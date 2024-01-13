// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../script/DeployLite.s.sol";
import {Counter} from "../src/Counter.sol";

contract DeployCounter is DeployLite {
    function deployCounter() public returns (address counter) {
        bytes memory args = abi.encode(42);
        DeployState state = deployState("Counter", args);

        if (state == DeployState.None || state == DeployState.Older) {
            vm.broadcast();
            counter = deploy("Counter", args);
        }
    }

    function run() public virtual {
        deployCounter();
    }
}
