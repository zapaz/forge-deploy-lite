// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../../src/DeployLite.s.sol";
import {Complex} from "../../src/examples/Complex.sol";

import {console} from "forge-std/console.sol";
import {Counter} from "../../src/examples/Counter.sol";

contract DeployComplex is DeployLite {
    function deployComplex() public returns (address) {
        address deployer = vm.envAddress("DEPLOYER");
        bytes memory args = abi.encode(1_000, 1);

        // immut = true only works when deployer is NOT the sender (or this)
        assert(deployer != msg.sender);
        vm.prank(deployer);
        DeployState state = deployState("Complex", args, true);

        if (state == DeployState.None || state == DeployState.Older) {
            vm.broadcast(deployer);
            address complex = deploy("Complex", args);
            console.log("deployCounter   active fork E", block.number, vm.getNonce(deployer));
        }
        return readAddress("Complex");
    }

    function run() public virtual {
        deployComplex();
    }
}
