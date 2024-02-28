// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployLiteRWJson {
    function setJsonFile(string calldata) external;
    function setRecording(bool) external;
    function readAddress(string calldata) external returns (address);
    function writeAddress(string calldata, address) external;
}
