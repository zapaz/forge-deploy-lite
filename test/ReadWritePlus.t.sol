// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable quotes, no-console, no-empty-blocks, func-name-mixedCase

import "forge-std/Test.sol";
import "src/DeployLite.s.sol";

contract ReadWritePlusTest is Test, DeployLite {
    using stdJson for string;

    string public pathJson;
    uint256 public count;
    string public json;
    address public oldAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public newAddress = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

    function test_ReadWritePlus_ReadUint() public view {
        uint256 num = readUint("nombre");
        assert(num > 0);

        uint256 num2 = readUint("nombre2");
        assert(num2 == 0);

        address addr = readAddress("This");
        assert(addr != address(0));

        address addr2 = readAddress("Nothing");
        assert(addr2 == address(0));
    }

    function test_ReadWritePlus_KeyDelete() public {
        init();
        console.log(json);

        json = _keyDelete(json, "31337", "Routeur");
        json.write(pathJson);

        json = vm.readFile(pathJson);
        console.log(json);
    }

    function test_ReadWritePlus_KeyInsert() public {
        init();
        console.log(json);

        json = _keyUpdate(json, "31337", "Routeur2", vm.toString(newAddress));
        json.write(pathJson);

        json = vm.readFile(pathJson);
        console.log(json);
    }

    function test_ReadWritePlus_KeyUpdate() public {
        init();

        console.log(json);
        assert(abi.decode(vm.parseJson(json, ".31337.Routeur"), (address)) == oldAddress);

        string memory jsonNewAddress = vm.toString(newAddress);
        jsonNewAddress.write(pathJson, ".31337.Routeur");
        json = vm.readFile(pathJson);

        console.log(json);
        assert(abi.decode(vm.parseJson(json, ".31337.Routeur"), (address)) == newAddress);
    }

    function test_ReadWritePlus_OK() public {
        init();
        assert(true);
    }

    function init() public {
        pathJson = string.concat("test/files/", vm.toString(abi.encodePacked(msg.sig)), ".json");
        if (vm.isFile(pathJson)) vm.removeFile(pathJson);

        vm.serializeString("network", "chainName", "local");
        vm.serializeString("network", "nombre", "324");
        string memory jsonNetwork = vm.serializeAddress("network", "Routeur", oldAddress);

        json = vm.serializeString("root", "31337", jsonNetwork);
        json.write(pathJson);
        json = vm.readFile(pathJson);
    }
}
