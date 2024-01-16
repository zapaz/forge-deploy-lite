// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../../src/DeployLite.s.sol";
import {Complex} from "../../src/examples/Complex.sol";

contract DeployComplex is DeployLite {
    function deployComplex() public returns (address) {
        address anvil8 = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
        uint256 anvil8Key = 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97;
        bytes memory args = abi.encode(abi.encode(1_000, 1));

        vm.startPrank(anvil8);
        DeployState state = deployState("Complex", args, true);
        vm.stopPrank();

        if (state == DeployState.None || state == DeployState.Older) {
            vm.broadcast(anvil8Key);
            deploy("Complex", args);
        }

        return readAddress("Complex");
    }

    function run() public virtual {
        deployComplex();
    }
}
