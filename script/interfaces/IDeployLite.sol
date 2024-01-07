// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeployLite {
    enum DeployedState {
        None,
        Older,
        Newly,
        Already,
        Previously
    }

    function deploy(string memory name) external returns (DeployedState);
    function deploy(string memory name, bytes memory data) external returns (DeployedState);
    function deploy(string memory name, bytes memory data, bool noUpdate) external returns (DeployedState);
}
