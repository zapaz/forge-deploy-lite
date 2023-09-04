// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    function test_OK() public pure {
        assert(true);
    }

    function test_existsJsonFile() public {
        rwJson.setJsonFile("json.addresses");
        assertFalse(rwJson.existsJsonFile());
    }

    function test_existsJsonFileNot() public {
        rwJson.setJsonFile("addresses.json");
        assertTrue(rwJson.existsJsonFile());
    }

    function test_createsJsonFile() public {
        string memory jsonFile = "test/json/test_createsJsonFile.json";
        rwJson.setJsonFile(jsonFile);

        if (rwJson.existsJsonFile()) vm.removeFile(jsonFile);
        assertFalse(rwJson.existsJsonFile());

        rwJson.createJsonFile();
        assertTrue(rwJson.existsJsonFile());
    }

    function test_existsJsonNetwork() public {
        rwJson.setJsonFile("test/json/test_existsJsonNetwork.json");
        assertTrue(rwJson.existsJsonNetwork());
    }

    function test_existsJsonNetworkNot() public {
        rwJson.setJsonFile("test/json/test_existsJsonNetworkNot.json");
        assertFalse(rwJson.existsJsonNetwork());
    }

    function test_createsJsonNetwork() public {
        string memory jsonFile = "test/json/test_createsJsonNetwork.json";
        rwJson.setJsonFile(jsonFile);

        if (!rwJson.existsJsonNetwork()) {
            rwJson.createJsonNetwork();
            assertTrue(rwJson.existsJsonNetwork());
        }
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

        assertEq(rwJson.readAddress("NoTestHere"), address(0));
    }
}
