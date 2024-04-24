// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../../src/DeployLite.s.sol";
import {Complex} from "../../src/examples/Complex.sol";

import {console} from "forge-std/console.sol";

contract DeployComplex is DeployLite {
    function deployComplex() public returns (address) {
        bytes memory args = abi.encode(1_000, 1);

        DeployState state = deployState("Complex", args);

        if (state == DeployState.None || state == DeployState.Older) {
            vm.broadcast();
            deploy("Complex", args);
        }
        return readAddress("Complex");
    }

    function run() public virtual {
        deployComplex();
    }
}
