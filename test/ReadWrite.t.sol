// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/DeployLiteRWJson.s.sol";

contract ReadWriteJsonTest is Test, DeployLiteRWJson {
    using stdJson for string;

    string testFile;

    function test_ReadWrite_OK() public pure {
        assert(true);
    }

    function test_ReadWrite_Bytes32() public view {
        assertEq(readBytes32("Id32"), 0x1b65ea1a8e546cc3009bce9a1534d01fc5e09f04603be6a067de97db81614970);
    }

    function test_ReadWrite_String() public view {
        assertEq(readString("chainName"), "local");
    }

    function test_ReadWrite_Address() public {
        writeAddress("This", address(0));
        writeAddress("This", address(this));
        assertEq(readAddress("This"), address(this));

        writeAddress("MsgSender", address(0));
        writeAddress("MsgSender", msg.sender);
        assertEq(readAddress("MsgSender"), msg.sender);
    }
}
