// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "script/ReadWriteJson.sol";

contract ReadWriteJsonTest is Test {
    using stdJson for string;

    ReadWriteJson rwJson;
    string testFile;

    function setUpJson(string memory name) public {
        testFile = string.concat("test/json/", name, ".json");
        rwJson.setJsonFile(testFile);

        try vm.removeFile(testFile) {} catch (bytes memory) {}
        vm.writeLine(testFile, string.concat('{\n  "', vm.toString(block.chainid), '": {\n    "Test": ""\n  }\n}'));
        vm.closeFile(testFile);
    }

    function setUp() public {
        rwJson = new ReadWriteJson();
    }

    function testOK() public {
        assert(true);
    }

    function test_setUpJson() public {
        setUpJson("test_setUpJson");

        assertEq(rwJson.jsonFile(), testFile);
        assertEq(rwJson.readAddress("Test"), address(0x20));
    }

    function test_SetFilePath() public {
        string memory otherFile = "../other/other.json";

        rwJson.setJsonFile(otherFile);
        assertEq(rwJson.jsonFile(), otherFile);
    }

    function test_writeAddressExists() public {
        setUpJson("test_writeAddressExists");

        rwJson.writeAddress("Test", address(this));
        assertEq(rwJson.readAddress("Test"), address(this));
    }

    function test_writeAddressNotExists() public {
        setUpJson("test_writeAddressNotExists");

        rwJson.writeAddress("NoTestHere", address(this));
        assertEq(rwJson.readAddress("NoTestHere"), address(this));
    }

    function test_readAddressExists() public {
        setUpJson("test_readAddressExists");

        rwJson.writeAddress("Test", address(this));
        assertEq(rwJson.readAddress("Test"), address(this));
    }

    function test_readAddressNotExists() public {
        setUpJson("test_readAddressNotExists");

        assertEq(rwJson.readAddress("NoTestHere"), address(0x20));
    }
}
