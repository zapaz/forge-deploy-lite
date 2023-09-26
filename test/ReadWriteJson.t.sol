// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../script/ReadWriteJson.s.sol";

contract ReadWriteJsonTest is Test, ReadWriteJson {
    using stdJson for string;

    string testFile;

    function setUpJson(string memory name) public {
        testFile = string.concat("test/json/", name, ".json");
        setJsonFile(testFile);

        try vm.removeFile(testFile) {} catch (bytes memory) {}
        vm.writeLine(testFile, string.concat('{\n  "', vm.toString(block.chainid), '": {\n    "Test": ""\n  }\n}'));
        vm.closeFile(testFile);
    }

    function setUp() public {}

    function test_OK() public pure {
        assert(true);
    }

    function test_existsJsonFile() public {
        setJsonFile("addresses.json");
        assertTrue(_existsJsonFile());
    }

    function test_existsNotJsonFile() public {
        setJsonFile("test/json/json.addresses");
        assertFalse(_existsJsonFile());
    }

    function test_createsJsonFile() public {
        string memory jsonFile = "test/json/test_createsJsonFile.json";
        setJsonFile(jsonFile);

        if (_existsJsonFile()) vm.removeFile(jsonFile);
        assertFalse(_existsJsonFile());

        _createJsonFile(block.chainid);
        assertTrue(_existsJsonFile());
    }

    function test_existsJsonNetwork() public {
        setJsonFile("test/json/test_existsJsonNetwork.json");
        assertTrue(_existsJsonNetwork(block.chainid));
    }

    function test_existsJsonNetworkNot() public {
        setJsonFile("test/json/test_existsJsonNetworkNot.json");
        assertFalse(_existsJsonNetwork(block.chainid));
    }

    function test_createsJsonNetwork() public {
        string memory jsonFile = "test/json/test_createsJsonNetwork.json";
        setJsonFile(jsonFile);

        if (!_existsJsonNetwork(block.chainid)) {
            _createJsonNetwork(block.chainid);
            assertTrue(_existsJsonNetwork(block.chainid));
        }
    }

    function test_setUpJson() public {
        setUpJson("test_setUpJson");

        assertEq(jsonFile, testFile);
        assertEq(readAddress("Test"), address(0x20));
    }

    function test_SetFilePath() public {
        string memory otherFile = "../other/other.json";

        setJsonFile(otherFile);
        assertEq(jsonFile, otherFile);
    }

    function test_writeAddressExists() public {
        setUpJson("test_writeAddressExists");

        writeAddress("Test", address(this));
        assertEq(readAddress("Test"), address(this));
    }

    function test_writeAddressNotExists() public {
        setUpJson("test_writeAddressNotExists");

        writeAddress("NoTestHere", address(this));
        assertEq(readAddress("NoTestHere"), address(this));
    }

    function test_readAddressExists() public {
        setUpJson("test_readAddressExists");

        writeAddress("Test", address(this));
        assertEq(readAddress("Test"), address(this));
    }

    function test_readAddressNotExists() public {
        setUpJson("test_readAddressNotExists");

        assertEq(readAddress("NoTestHere"), address(0));
    }
}
