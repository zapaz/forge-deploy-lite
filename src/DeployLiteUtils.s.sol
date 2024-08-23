// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {IDeployLiteUtils} from "./interfaces/IDeployLiteUtils.sol";

contract DeployLiteUtils is IDeployLiteUtils, Script {
    function log3(address addr, string memory name, string memory description) public pure override(IDeployLiteUtils) {
        log4(addr, name, description, "");
    }

    function log4(address addr, string memory name, string memory description, string memory more)
        public
        pure
        override(IDeployLiteUtils)
    {
        console.log(addr, _stringPad20(name), _stringPad20(description), _stringPad20(more));
    }

    function logCallers(string memory label) public override(IDeployLiteUtils) {
        (VmSafe.CallerMode callerMode, address msgSender, address txOrigin) = vm.readCallers();
        string memory mode = _getCallerModeName(uint256(callerMode));

        if (msgSender == txOrigin) {
            log4(txOrigin, label, "msgSender and txOrigin", mode);
        } else {
            log4(txOrigin, label, "txOrigin", mode);
            log4(msgSender, label, "msgSender", mode);
        }
    }

    function isBroadcasting() public returns (bool) {
        (VmSafe.CallerMode callerMode,,) = vm.readCallers();
        return (callerMode == VmSafe.CallerMode.Broadcast || callerMode == VmSafe.CallerMode.RecurrentBroadcast);
    }

    function sliceBytes(bytes calldata data, uint256 start, uint256 end)
        public
        pure
        override(IDeployLiteUtils)
        returns (bytes memory)
    {
        return bytes(data[start:end]);
    }

    function sliceString(string calldata data, uint256 start, uint256 end)
        public
        pure
        override(IDeployLiteUtils)
        returns (string memory)
    {
        return string(sliceBytes(bytes(data), start, end));
    }

    function _bytesPad5(uint256 n) internal pure returns (string memory) {
        require(n <= 24_576, "Too big Dragon");
        bytes memory b = new bytes(5);
        b[0] = bytes1(n < 10_000 ? 0x20 : uint8(n / 10_000 % 10) + 0x30);
        b[1] = bytes1(n < 1_000 ? 0x20 : uint8(n / 1_000 % 10) + 0x30);
        b[2] = bytes1(n < 100 ? 0x20 : uint8(n / 100 % 10) + 0x30);
        b[3] = bytes1(n < 10 ? 0x20 : uint8(n / 10 % 10) + 0x30);
        b[4] = bytes1(uint8(n % 10) + 0x30);
        return string.concat(string(b), " bytes");
    }

    function _stringPad20(string memory input) internal pure returns (string memory output) {
        return _stringPad(input, 20);
    }

    function _stringPad(string memory input, uint256 len) internal pure returns (string memory output) {
        bytes memory str = bytes(input);
        while (str.length < len) {
            str = abi.encodePacked(str, " ");
        }
        output = string(str);
    }

    function _stringToUint(string memory str) internal pure returns (uint256 result) {
        bytes memory b = bytes(str);
        uint256 len = b.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function _getCallerModeName(uint256 callerMode) internal pure returns (string memory) {
        require(callerMode < 5, "Unknown mode");
        string[5] memory modes = ["None", "Broadcast", "RecurrentBroadcast", "Prank", "RecurrentPrank"];
        return modes[callerMode];
    }

    function _bytesEqual(bytes memory b1, bytes memory b2) internal pure returns (bool) {
        return keccak256(b1) == keccak256(b2);
    }

    function _stringEqual(string memory s1, string memory s2) internal pure returns (bool) {
        return _bytesEqual(bytes(s1), bytes(s2));
    }
}
