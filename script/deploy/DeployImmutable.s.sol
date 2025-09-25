// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DeployLite} from "../../src/DeployLite.s.sol";

contract DeployImmutable is DeployLite {
    function deployImmutable() public returns (address) {
        return deployLite("Immutable", abi.encode(41, 3));
    }

    function run() public virtual {
        deployImmutable();
    }
}
