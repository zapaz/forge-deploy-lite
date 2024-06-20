// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

import {IDeployLite} from "./interfaces/IDeployLite.sol";
import {DeployLiteRWJson} from "./DeployLiteRWJson.s.sol";

// import {console} from "forge-std/console.sol";

contract DeployLite is Script, IDeployLite, DeployLiteRWJson {
    mapping(string => DeployState) private _state;
    mapping(string => bool) private _created;

    function deployLite(string memory name) public returns (address addr) {
        return _deploy(name, "", false);
    }

    function deployLite(string memory name, bytes memory data) public returns (address addr) {
        return _deploy(name, data, false);
    }

    function deployLiteImmutable(string memory name, bytes memory data) public returns (address addr) {
        return _deploy(name, data, true);
    }

    function deployState(string memory name) public returns (DeployState state) {
        return _deployState(name, "", false);
    }

    function deployState(string memory name, bytes memory data) public returns (DeployState state) {
        return _deployState(name, data, true);
    }

    // read deployed state of contract (compares to next deploy code) :
    // none deployed, older deployed (different), already deployed (identical), new (just deployed)
    // if immut, caller has to prank sender user, when msg.sender is checked inside constructor
    function _deployState(string memory name, bytes memory data, bool immut) private returns (DeployState state) {
        string memory nameLast = string.concat(name, _LAST);
        address addrName = _readAddress(name);
        address addrNameLast = _readAddress(nameLast);
        string memory deployedLabel;
        address addr;

        bytes memory deployedCodeExpected;
        if (immut) {
            deployedCodeExpected = _getDeployedCodeExpected(name, data);
        } else {
            deployedCodeExpected = _getDeployedCodeExpected(name);
        }
        DeployState stateBefore = _state[name];

        if (_isSameCode(deployedCodeExpected, addrNameLast.code)) {
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
        } else if (_isSameCode(deployedCodeExpected, addrName.code)) {
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

    // deployLite deploy named contract if not yet deployed or already deployed with different code
    // data contains constructor arguments abi.encoded
    // immut is to indicate that immutable variables are used, so deployed code depends on
    // these data agurments (or more generraly that deployed code is modify during creation by creation)
    function _deploy(string memory name, bytes memory data, bool immut) internal returns (address addr) {
        DeployState state = _deployState(name, data, immut);

        if (state == DeployState.None || state == DeployState.Older) {
            vm.startBroadcast();
            deploy(name, data);
            vm.stopBroadcast();
        }

        return readAddress(name);
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

    function _getDeployedCodeExpected(string memory name) internal view returns (bytes memory) {
        return vm.getDeployedCode(string.concat(name, ".sol:", name));
    }

    // simulate create to get expected deployed code
    // on another fork in order NOT to increment deployer nonce...
    function _getDeployedCodeExpected(string memory name, bytes memory data)
        internal
        returns (bytes memory deployedCodeExpected)
    {
        uint256 activeFork = vm.activeFork();
        uint256 activeChainId = block.chainid;

        vm.createSelectFork(vm.envString("CHAIN"));
        require(activeChainId == block.chainid, "CHAIN should be same as fork");

        deployedCodeExpected = _create(_getCreationCode(name, data)).code;

        vm.selectFork(activeFork);
    }

    function _isSameCode(bytes memory code1, bytes memory code2) internal view returns (bool) {
        return _bytesEqual(_removeCbor(code1), _removeCbor(code2));
    }

    function _isDeployed(address addr) internal view returns (bool) {
        return addr.code.length > 0;
    }

    function _getCborLength(bytes memory bytecode) internal view returns (uint16) {
        return bytecode.length < 2 ? 0 : uint16(bytes2(this.sliceBytes(bytecode, bytecode.length - 2, bytecode.length)));
    }

    function _removeCbor(bytes memory bytecode) internal view returns (bytes memory) {
        uint256 len = _getCborLength(bytecode);
        return (bytecode.length >= len) ? this.sliceBytes(bytecode, 0, bytecode.length - len) : bytecode;
    }
}
