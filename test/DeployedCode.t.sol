// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Immutable} from "../src/Immutable.sol";
import {DeployLite} from "../script/DeployLite.s.sol";

contract DeployedCodeTest is Test, DeployLite {
    function setUp() public view {
        console.log("setUp");
    }

    function test_deployedCode_OK() public pure {
        assert(true);
    }

    function test_deployedCode_1() public {
        bytes memory deployedCode = vm.getDeployedCode("Immutable.sol");
        console.log("test_deployedCode_1 ~ deployedCode.length:", deployedCode.length);
        console.logBytes(deployedCode);

        bytes memory code = vm.getCode("Immutable.sol");
        console.log("test_deployedCode_1 ~         code.length:", code.length);
        console.logBytes(code);

        Immutable imm = new Immutable(42);
        console.log("test_deployedCode_1 ~ imm.code.length:", address(imm).code.length);
        console.logBytes(address(imm).code);

        bytes memory codeToDeploy = vm.getCode("Immutable.sol");
        console.log("test_deployedCode_1 ~ getDeployedCode.length:", codeToDeploy.length);
        console.logBytes(codeToDeploy);
    }

    function test_deployedCode_2() public {
        Immutable imm = new Immutable(42);
        console.log("test_deployedCode_2 ~ imm.code.length:", address(imm).code.length);
        console.logBytes(address(imm).code);

        bytes memory args = abi.encode(42);
        bytes memory bytecode = abi.encodePacked(vm.getCode("Immutable.sol"), args);
        address anotherAddress;
        assembly {
            anotherAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        console.log("test_deployedCode_2 ~ imm.code.length:", anotherAddress.code.length);
        console.logBytes(anotherAddress.code);

        assertEq0(address(imm).code, anotherAddress.code);
    }

    function test_deployedCode_3() public {
        Immutable imm = new Immutable(42);
        console.log("test_deployedCode_3 ~ imm.code.length:", address(imm).code.length);
        console.logBytes(address(imm).code);

        bytes memory code = _getCodeToDeploy("Immutable", abi.encode(42));
        console.log("test_deployedCode_3 ~ code.length:", code.length);
        console.logBytes(code);

        assertEq0(address(imm).code, code);
    }
}
