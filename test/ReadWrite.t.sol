// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/DeployLiteRWJson.s.sol";

contract ReadWriteJsonTest is Test, DeployLiteRWJson("addresses.json") {
    using stdJson for string;

    string testFile;

    function test_ReadWrite_OK() public {
        init("ReadWrite_OK");

        assertEq(readString("chainName"), "local");
        assertEq(readString("num"), "324");
        assertEq(readString("OK"), "true");
    }

    function test_ReadWrite_Bytes32() public {
        init("ReadWrite_Bytes32");

        assertEq(readBytes32("Id32"), 0x1b65ea1a8e546cc3009bce9a1534d01fc5e09f04603be6a067de97db81614970);
    }

    function test_ReadWrite_String() public {
        init("ReadWrite_String");

        assertEq(readString("chainName"), "local");
    }

    function test_ReadWrite_Uint() public {
        init("ReadWrite_Uint");

        assertEq(readUint("num"), 324);
    }

    function test_ReadWrite_Address() public {
        init("ReadWrite_Address");

        writeAddress("This", address(0));
        writeAddress("This", address(this));
        assertEq(readAddress("This"), address(this));

        writeAddress("MsgSender", address(0));
        writeAddress("MsgSender", msg.sender);
        assertEq(readAddress("MsgSender"), msg.sender);
    }

    function init(string memory fileName) public {
        string memory pathJson = string.concat("test/files/", fileName, ".json");
        if (vm.isFile(pathJson)) vm.removeFile(pathJson);

        vm.serializeString("network", "chainName", "local");
        vm.serializeString("network", "num", "324");
        vm.serializeString("network", "arrray", "[1,2,3]");
        vm.serializeString("network", "Id32", "0x1b65ea1a8e546cc3009bce9a1534d01fc5e09f04603be6a067de97db81614970");
        string memory jsonNetwork = vm.serializeString("network", "OK", "true");

        string memory json = vm.serializeString("root", "31337", jsonNetwork);
        json.write(pathJson);
        console.log(json);

        assertEq(
            vm.parseJsonString(json, ".31337.Id32"),
            "0x1b65ea1a8e546cc3009bce9a1534d01fc5e09f04603be6a067de97db81614970"
        );

        setJsonFile(pathJson);
        console.log(vm.readFile(pathJson));
    }
}
