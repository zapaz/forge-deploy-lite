// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReadWriteJson {
    function setJsonFile(string calldata filePath) external;
    function readAddress(string calldata name) external returns (address);
    function writeAddress(string calldata name, address addr) external;
}
