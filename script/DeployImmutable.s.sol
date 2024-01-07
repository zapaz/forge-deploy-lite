// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../script/DeployLite.s.sol";
import {Immutable} from "../src/Immutable.sol";

// import {console} from "forge-std/console.sol";

contract DeployImmutable is DeployLite {
    function deployImmutable() public {
        DeployedState state = deploy("Immutable", abi.encode(42));

        if (state == DeployedState.Newly) {
            vm.startBroadcast();
            // put here additional code to intialize your deployed contract ...
            vm.stopBroadcast();
        }
    }

    function run() public virtual {
        deployImmutable();
    }
}
