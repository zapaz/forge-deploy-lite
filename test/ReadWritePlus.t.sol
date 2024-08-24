// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/DeployLite.s.sol";

contract ReadWritePlusTest is Test, DeployLite {
    using stdJson for string;

    string public pathJson;
    uint256 public count;
    string public json;
    address public oldAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public newAddress = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

    function test_ReadWritePlus_ReadUint() public {
        init("ReadUint");

        uint256 num = readUint("num");
        assert(num == 324);

        uint256 num9 = readUint("num9");
        assert(num9 == 0);

        address addr = readAddress("Router");
        assert(addr != address(0));

        address addr9 = readAddress("Router9");
        assert(addr9 == address(0));
    }

    function test_ReadWritePlus_KeyDelete() public {
        init("KeyDelete");
        console.log(json);
        assert(readAddress("Router") == oldAddress);

        json = _keyDelete(json, "31337", "Router");
        json.write(pathJson);

        json = vm.readFile(pathJson);
        console.log(json);
        assert(readAddress("Router") == address(0));
    }

    function test_ReadWritePlus_KeyInsert() public {
        init("KeyInsert");
        console.log(json);
        assert(readAddress("Router2") == address(0));

        json = _keyUpdate(json, "31337", "Router2", vm.toString(newAddress));
        json.write(pathJson);

        json = vm.readFile(pathJson);
        console.log(json);
        assert(readAddress("Router2") == newAddress);
    }

    function test_ReadWritePlus_KeyUpdate() public {
        init("KeyUpdate");

        console.log(json);
        assert(readAddress("Router") == oldAddress);

        string memory jsonNewAddress = vm.toString(newAddress);
        jsonNewAddress.write(pathJson, ".31337.Router");
        json = vm.readFile(pathJson);

        console.log(json);
        assert(readAddress("Router") == newAddress);
    }

    function test_ReadWritePlus_OK() public {
        init("OK");

        string[] memory keys = vm.parseJsonKeys(json, "$");
        assertEq(keys[0], "31337");

        string[] memory names = vm.parseJsonKeys(json, ".31337");
        assertEq(names[0], "Router");
        assertEq(names[1], "chainName");
        assertEq(names[2], "num");

        assertEq(readAddress("Router") , oldAddress);
        assertEq(readString("chainName"), "local");
        assertEq(readUint("num"), 324);
    }

    function name4bytes() public pure returns (string memory) {
        return vm.toString(abi.encodePacked(msg.sig));
    }

    function init(string memory fileName) public {
        pathJson = string.concat("test/files/", fileName, ".json");
        if (vm.isFile(pathJson)) vm.removeFile(pathJson);

        vm.serializeString("network", "chainName", "local");
        vm.serializeString("network", "num", "324");
        string memory jsonNetwork = vm.serializeAddress("network", "Router", oldAddress);

        json = vm.serializeString("root", "31337", jsonNetwork);
        json.write(pathJson);
        json = vm.readFile(pathJson);

        setJsonFile(pathJson);
    }
}
