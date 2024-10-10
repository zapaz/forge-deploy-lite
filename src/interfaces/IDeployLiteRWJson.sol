// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IDeployLiteRWJson {
    function readAddress(string memory) external view returns (address);
    function readBytes(string memory) external view returns (bytes memory);
    function readBytes32(string memory) external view returns (bytes32);
    function readString(string memory) external view returns (string memory);
    function readUint(string memory) external view returns (uint256);

    function removeAddress(string memory) external;
    function writeAddress(string calldata, address) external;

    function setJsonFile(string memory) external;
    function setRecording(bool) external;
}
