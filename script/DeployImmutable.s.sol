// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../script/DeployLite.s.sol";
import {Immutable} from "../src/Immutable.sol";

contract DeployImmutable is DeployLite {
    function deployImmutable() public returns (address immutableAddress) {
        bytes memory args = abi.encode(41, 3);
        DeployState state = deployState("Immutable", args);

        if (state == DeployState.None || state == DeployState.Older) {
            vm.broadcast();
            deploy("Immutable", args);
        }

        immutableAddress = readAddress("Immutable");
    }

    function run() public virtual {
        deployImmutable();
    }
}
