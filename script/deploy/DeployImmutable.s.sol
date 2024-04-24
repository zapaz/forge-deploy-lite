// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "../../src/DeployLite.s.sol";
import {Immutable} from "../../src/examples/Immutable.sol";

contract DeployImmutable is DeployLite {
    function deployImmutable() public returns (address) {
        return deployLiteImmutable("Immutable", abi.encode(41, 3));
    }

    function run() public virtual {
        deployImmutable();
    }
}
