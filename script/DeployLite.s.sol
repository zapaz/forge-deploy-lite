// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

import {IDeployLite} from "./interfaces/IDeployLite.sol";
import {DeployLiteRWJson} from "./DeployLiteRWJson.s.sol";

// import {console} from "forge-std/console.sol";

contract DeployLite is Script, IDeployLite, DeployLiteRWJson {
    function deployState(string memory name, bytes memory data) public returns (DeployState state) {
        address addrName = _readAddress(name);
        address addrNameLast = _readAddress(string.concat(name, _LAST));
        string memory deployedLabel;
        address addr;

        if (_isSameDeployed(name, data, addrName)) {
            addr = addrName;
            deployedLabel = "Already deployed";
            state = DeployState.Already;
        } else if (_isSameDeployed(name, data, addrNameLast)) {
            addr = addrNameLast;
            deployedLabel = "Newly deployed";
            writeAddress(name, addr);
            state = DeployState.Newly;
        } else if (_isDeployed(addrName)) {
            addr = addrName;
            deployedLabel = "Older deployment";
            state = DeployState.Older;
        } else {
            addr = address(0);
            deployedLabel = "No deployment";
            state = DeployState.None;
        }

        log4(addr, _stringPad20(name), deployedLabel, _bytesPad5(addr.code.length));
    }

    function deployState(string memory name) public returns (DeployState state) {
        return deployState(name, "");
    }

    function deploy(string memory name, bytes memory data) public returns (address addr) {
        bytes memory code = _getCreationCode(name, data);

        addr = _create(code);

        assert(addr != address(0));
        writeAddress(string.concat(name, _LAST), addr);

        log4(addr, _stringPad20(name), "New deployment", _bytesPad5(addr.code.length));
    }

    function deploy(string memory name) public returns (address addr) {
        return deploy(name, "");
    }

    function _create(bytes memory bytecode) internal returns (address addr) {
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            // addr := create2(0, add(0x20, bytecode), mload(bytecode), salt)
        }
    }

    function _getCreationCode(string memory name) internal view returns (bytes memory) {
        return vm.getCode(string.concat(name, ".sol:", name));
    }

    function _getCreationCode(string memory name, bytes memory data) internal view returns (bytes memory) {
        return abi.encodePacked(_getCreationCode(name), data);
    }

    function _getCodeToDeploy(string memory name) internal view returns (bytes memory) {
        return vm.getDeployedCode(string.concat(name, ".sol:", name));
    }

    function _getCodeToDeploy(string memory name, bytes memory data) internal returns (bytes memory code) {
        return _create(_getCreationCode(name, data)).code;
    }

    function _isSameCode(bytes memory code1, bytes memory code2) internal view returns (bool) {
        return _bytesEqual(_removeDeployedCodeMetadata(code1), _removeDeployedCodeMetadata(code2));
    }

    function _isDeployed(address addr) internal view returns (bool) {
        return addr.code.length > 0;
    }

    function _isSameDeployed(string memory name, bytes memory data, address addr) internal returns (bool) {
        if (!_isDeployed(addr)) return false;

        bytes memory code = _getCodeToDeploy(name, data);
        if (_isSameCode(code, addr.code)) return true;

        return false;
    }

    function _getCborLength(bytes memory bytecode) internal view returns (uint16) {
        return bytecode.length < 2 ? 0 : uint16(bytes2(this.sliceBytes(bytecode, bytecode.length - 2, bytecode.length)));
    }

    function _removeDeployedCodeMetadata(bytes memory bytecode) internal view returns (bytes memory) {
        uint256 len = _getCborLength(bytecode);
        return (bytecode.length >= len) ? this.sliceBytes(bytecode, 0, bytecode.length - len) : bytecode;
    }
}
