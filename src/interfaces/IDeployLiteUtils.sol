// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IDeployLiteUtils {
    function sliceBytes(bytes memory data, uint256 start, uint256 end) external pure returns (bytes memory);
    function log3(address addr, string memory name, string memory description) external view;
    function log4(address addr, string memory name, string memory description, string memory more) external view;
    function logCallers(string memory label) external;
}
