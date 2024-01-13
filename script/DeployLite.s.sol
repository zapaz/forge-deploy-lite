// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

import {IDeployLite} from "./interfaces/IDeployLite.sol";
import {DeployLiteRWJson} from "./DeployLiteRWJson.s.sol";

// import {console} from "forge-std/console.sol";

contract DeployLite is Script, IDeployLite, DeployLiteRWJson {
    mapping(string => DeployState) private _state;
    mapping(string => bool) private _created;

    function deployState(string memory name, bytes memory data) public returns (DeployState state) {
        require(!isBroadcasting(), "deployState must be outside Broadcast");

        string memory nameLast = string.concat(name, _LAST);
        address addrName = _readAddress(name);
        address addrNameLast = _readAddress(nameLast);
        string memory deployedLabel;
        address addr;

        DeployState stateBefore = _state[name];

        if (_isSameDeployed(name, data, addrNameLast)) {
            addr = addrNameLast;
            if (_created[name]) {
                assert(stateBefore == DeployState.New);
                state = DeployState.New;
            } else {
                deployedLabel = "Already deployed";
                state = DeployState.Already;
                writeAddress(name, addr);
                removeAddress(nameLast);
            }
        } else if (_isSameDeployed(name, data, addrName)) {
            addr = addrName;
            deployedLabel = "Already deployed";
            state = DeployState.Already;
        } else if (_isDeployed(addrName)) {
            addr = addrName;
            deployedLabel = "Older deployment";
            state = DeployState.Older;
        } else {
            addr = address(0);
            deployedLabel = "No deployment";
            state = DeployState.None;
        }

        if (state != stateBefore) {
            _state[name] = state;
            log4(addr, _stringPad20(name), deployedLabel, _bytesPad5(addr.code.length));
        }
    }

    function deployState(string memory name) public returns (DeployState state) {
        return deployState(name, "");
    }

    function deploy(string memory name, bytes memory data) public returns (address addr) {
        require(isBroadcasting(), "deploy must be inside Broadcast");

        bytes memory code = _getCreationCode(name, data);

        addr = _create(code);

        writeAddress(string.concat(name, _LAST), addr);
        _created[name] = true;
        _state[name] = DeployState.New;

        log4(addr, _stringPad20(name), "New deployment", _bytesPad5(addr.code.length));
    }

    function deploy(string memory name) public returns (address addr) {
        return deploy(name, "");
    }

    function _create(bytes memory bytecode) internal returns (address addr) {
        require(bytecode.length > 0, "create failed: bytecode empty");

        assembly {
            addr := create(callvalue(), add(0x20, bytecode), mload(bytecode))
            // addr := create2(callvalue(), add(0x20, bytecode), mload(bytecode), salt)
        }

        require(addr != address(0), "create failed: address 0");
        require(addr.code.length > 0, "create failed: code empty");
    }

    function _getCreationCode(string memory name) internal view returns (bytes memory) {
        return vm.getCode(string.concat(name, ".sol:", name));
    }

    function _getCreationCode(string memory name, bytes memory data) internal view returns (bytes memory) {
        return bytes.concat(_getCreationCode(name), data);
    }

    function _getCodeToDeploy(string memory name) internal view returns (bytes memory) {
        return vm.getDeployedCode(string.concat(name, ".sol:", name));
    }

    function _getCodeToDeploy(string memory name, bytes memory data) internal returns (bytes memory code) {
        return _create(_getCreationCode(name, data)).code;
    }

    function _isSameCode(bytes memory code1, bytes memory code2) internal view returns (bool) {
        return _bytesEqual(_removeCbor(code1), _removeCbor(code2));
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

    function _removeCbor(bytes memory bytecode) internal view returns (bytes memory) {
        uint256 len = _getCborLength(bytecode);
        return (bytecode.length >= len) ? this.sliceBytes(bytecode, 0, bytecode.length - len) : bytecode;
    }
}
