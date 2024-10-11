// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/DeployLiteRWJson.s.sol";

contract ReadWriteJsonTest is Test, DeployLiteRWJson("addresses.json") {
    using stdJson for string;

    string testFile;

    function test_ReadWriteJson_OK() public pure {
        assert(true);
    }

    function test_ReadWriteJson_setFilePath() public {
        string memory otherFile = "otherFile.json";

        setJsonFile(otherFile);
        assertEq(_jsonFile, otherFile);
    }

    function test_ReadWriteJson_readAddressExists() public {
        setJsonFile("out/test_ReadWriteJson_readAddressExists.json");
        vm.writeJson(
            string.concat('{"', vm.toString(block.chainid), '":{"Test":"', vm.toString(address(this)), '"}}'), _jsonFile
        );

        assertEq(readAddress("Test"), address(this));

        vm.removeFile(_jsonFile);
    }

    function test_ReadWriteJson_readAddressNotExists() public {
        setJsonFile("out/test_ReadWriteJson_readAddressNotExists.json");
        vm.writeJson(string.concat('{"', vm.toString(block.chainid), '":{"chainName":"local"}}'), _jsonFile);

        assertEq(readAddress("NoTestHere"), address(0));

        vm.removeFile(_jsonFile);
    }

    function test_ReadWriteJson_readAddressNetworkNotExists() public {
        setJsonFile("out/test_ReadWriteJson_readAddressNetworkNotExists.json");
        vm.writeJson(string.concat('{"42":{"Test":"', vm.toString(address(this)), '"}}'), _jsonFile);

        assertEq(readAddress("Test"), address(0));

        vm.removeFile(_jsonFile);
    }

    function test_ReadWriteJson_readAddressJsonNotExists() public {
        string memory otherFile = "out/otherZZZ.json";

        setJsonFile(otherFile);
        assertEq(readAddress("Test"), address(0));
    }

    function test_ReadWriteJson_writeAddressExists() public {
        setJsonFile("out/test_ReadWriteJson_writeAddressExists.json");
        vm.writeJson(
            string.concat('{"', vm.toString(block.chainid), '":{"Test":"', vm.toString(address(this)), '"}}'), _jsonFile
        );

        writeAddress("Test", address(42));
        assertEq(readAddress("Test"), address(42));

        vm.removeFile(_jsonFile);
    }

    function test_ReadWriteJson_writeAddressNotExists() public {
        setJsonFile("out/test_ReadWriteJson_writeAddressNotExists.json");
        vm.writeJson(
            string.concat('{"', vm.toString(block.chainid), '":{"Test":"', vm.toString(address(this)), '"}}'), _jsonFile
        );

        writeAddress("NoTestHere", address(42));
        assertEq(readAddress("NoTestHere"), address(42));

        vm.removeFile(_jsonFile);
    }

    function test_ReadWriteJson_writeAddressNetworkNotExists() public {
        setJsonFile("out/test_ReadWriteJson_writeAddressNetworkNotExists.json");
        vm.writeJson(string.concat('{"42":{"Test":"', vm.toString(address(this)), '"}}'), _jsonFile);

        writeAddress("Test", address(42));

        assertEq(readAddress("Test"), address(42));

        vm.removeFile(_jsonFile);
    }

    function test_ReadWriteJson_writeAddressJsonNotExists() public {
        string memory _jsonFile = "out/test_ReadWriteJson_writeAddressJsonNotExists.json";
        setJsonFile(_jsonFile);

        writeAddress("Test", address(42));

        assertEq(readAddress("Test"), address(42));

        vm.removeFile(_jsonFile);
    }

    function test_ReadWriteJson_removeAddress() public {
        setJsonFile("out/test_ReadWriteJson_removeAddress.json");
        vm.writeJson(
            string.concat(
                '{"',
                vm.toString(block.chainid),
                '":{"Address1":"',
                vm.toString(address(makeAddr("Un"))),
                '","Address2":"',
                vm.toString(address(makeAddr("Deux"))),
                '"}}'
            ),
            _jsonFile
        );

        writeAddress("Address3", address(makeAddr("Trois")));

        assertEq(readAddress("Address1"), address(makeAddr("Un")));
        assertEq(readAddress("Address2"), address(makeAddr("Deux")));
        assertEq(readAddress("Address3"), address(makeAddr("Trois")));

        vm.removeFile(_jsonFile);
    }
}
