// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../script/DeployLite.s.sol";
import {Immutable} from "../src/Immutable.sol";

// import {console} from "forge-std/console.sol";

contract DeployImmutable is DeployLite {
    function deployImmutable() public returns (address immutableAddress) {
        bytes memory args = abi.encode(42);
        DeployState state = deployState("Immutable", args);

        if (state == DeployState.None || state == DeployState.Older) {
            vm.startBroadcast();

            immutableAddress = deploy("Immutable", args);

            // put here additional code to intialize your deployed contract ...
            vm.stopBroadcast();
        }
    }

    function run() public virtual {
        deployImmutable();
    }
}
