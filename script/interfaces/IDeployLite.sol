// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployLite {
    function getAddress(string memory name) external returns (address);
    function getCodeDeployed(string memory name) external returns (bytes memory);
    function getCodeToDeploy(string memory name) external view returns (bytes memory);

    function isDeployed(string memory name) external returns (bool);
    function isSameDeployed(string memory name) external returns (bool);
    function isSameRunCode(bytes memory code1, bytes memory code2) external view returns (bool);

    function setDeployer(address deployer) external;
    function deploy(string memory name) external returns (address);
    function deploy(string memory name, bool update) external returns (address);
}
