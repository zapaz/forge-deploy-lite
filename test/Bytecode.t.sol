// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Test, console} from "forge-std/Test.sol";
import {HowMany} from "../src/examples/HowMany.sol";
import {DeployLite} from "../src/DeployLite.s.sol";

contract BytecodeTest is Test, DeployLite {
    address counter;

    function setUp() public {
        counter = address(new HowMany());
    }

    function test_bytecode_OK() public pure {
        assert(true);
    }

    function test_bytecode_to_deploy() public view {
        bytes memory code = vm.getDeployedCode("HowMany.sol:HowMany");

        console.log("code.length:", code.length);
        // console.logBytes(code);

        assert(code.length == 125);
    }

    function test_bytecode_cbor_length() public view {
        bytes memory code = vm.getDeployedCode("HowMany.sol:HowMany");

        uint256 cborLength = _getCborLength(code);
        console.log("cborLength:", cborLength);

        assert(cborLength == 51);
    }

    function test_bytecodes_with_metadata_differs() public view {
        bytes memory bytecode = vm.getDeployedCode("HowMany.sol:HowMany");
        bytes memory bytecodeBis = vm.getDeployedCode("HowManyBis.sol:HowMany");

        // same evm compiled code BUT different source comments
        assert(keccak256(bytecode) != keccak256(bytecodeBis));
    }

    function test_bytecodes_without_metadata_equals() public view {
        bytes memory bytecodeWithoutMetadata = _removeCbor(vm.getDeployedCode("HowMany.sol:HowMany"));
        bytes memory bytecodeBisWithoutMetadata = _removeCbor(vm.getDeployedCode("HowManyBis.sol:HowMany"));

        assert(keccak256(bytecodeWithoutMetadata) == keccak256(bytecodeBisWithoutMetadata));
    }
}
