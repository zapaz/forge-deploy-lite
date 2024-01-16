// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployLite {
    enum DeployState {
        Null,
        None,
        New,
        Already,
        Older
    }

    function deployState(string memory name, bytes memory data) external returns (DeployState state);
    function deployState(string memory name) external returns (DeployState state);

    function deploy(string memory name, bytes memory data) external returns (address addr);
    function deploy(string memory name) external returns (address addr);
}
