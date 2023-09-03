// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "src/counter.sol";
import {DeployLite} from "script/DeployLite.sol";

contract BytecodeTest is Test, DeployLite {
    address counter;

    function setUp() public {
        counter = address(new Counter());
    }

    function test_bytecode_OK() public pure {
        assert(true);
    }

    function test_bytecode_to_deploy() public view {
        bytes memory code = vm.getDeployedCode("Counter.sol:Counter");

        console.log("code.length:", code.length);
        console.logBytes(code);

        assert(code.length == 247);
    }

    function test_bytecode_cbor_length() public view {
        bytes memory code = vm.getDeployedCode("Counter.sol:Counter");

        uint256 cborLength = getCborLength(code);
        console.log("cborLength:", cborLength);

        assert(cborLength == 51);
    }

    function test_bytecodes_with_metadata_differs() public view {
        bytes memory bytecode = vm.getDeployedCode("Counter.sol:Counter");
        bytes memory bytecodeBis = vm.getDeployedCode("CounterBis.sol:Counter");

        // same evm compiled code BUT different source comments
        assert(keccak256(bytecode) != keccak256(bytecodeBis));
    }

    function test_bytecodes_without_metadata_equals() public view {
        bytes memory bytecode = vm.getDeployedCode("Counter.sol:Counter");
        bytes memory bytecodeBis = vm.getDeployedCode("CounterBis.sol:Counter");

        assert(keccak256(removeDeployedCodeMetadata(bytecode)) == keccak256(removeDeployedCodeMetadata(bytecodeBis)));
    }
}
