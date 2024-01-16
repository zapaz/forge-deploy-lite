// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../../src/DeployLite.s.sol";
import {Counter} from "../../src/examples/Counter.sol";

contract DeployCounter is DeployLite {
    function deployCounter() public returns (address) {
        return deployLite("Counter", abi.encode(42));
    }

    function run() public virtual {
        deployCounter();
    }
}
