// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "script/DeployLite.s.sol";
import {Counter} from "src/Counter.sol";

contract DeployCounter is DeployLite {
    function deployCounter() public returns (address counter) {
        vm.startBroadcast();

        counter = address(new Counter());

        // ...
        // put here additional code to intialize your deployed contract
        // warning : use deployer instead of `msg.sender`
        // ...

        vm.stopBroadcast();
    }

    function run() public virtual {
        deploy("Counter");
    }
}
