// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDeployLiteRWJson} from "./interfaces/IDeployLiteRWJson.sol";
import {DeployLiteUtils} from "./DeployLiteUtils.s.sol";
// import {console} from "forge-std/console.sol";

// Read and Write json file of this format
// {
//   "31337": {
//     "chainName": "local",
//     "Counter": "0x90193C961A926261B756D1E5bb255e67ff9498A1"
//   },
//   "11155111": {
//     "chainName": "sepolia",
//     "Counter": "0x34A1D3fff3958843C43aD80F30b94c510645C316"
//   }
// }
contract DeployLiteRWJson is IDeployLiteRWJson, DeployLiteUtils {
    string constant _LAST = "_last";

    mapping(string => address) internal _addresses;

    string internal _jsonFile = "addresses.json";

    bool internal _recording = true;

    function setJsonFile(string memory jsonFile_) public override(IDeployLiteRWJson) {
        _jsonFile = jsonFile_;
    }

    function setRecording(bool recording_) public override(IDeployLiteRWJson) {
        _recording = recording_;
    }

    // read `name_LAST` or `name` as Address
    function readAddress(string memory name) public view override(IDeployLiteRWJson) returns (address addr) {
        addr = _readAddress(string.concat(name, _LAST));
        if (addr == address(0)) addr = _readAddress(name);
    }

    // read `name` as Address
    function _readAddress(string memory name) internal view returns (address addr) {
        require(bytes(name).length > 0, "No name");

        if ((addr = _addresses[name]) != address(0)) return addr;

        string memory json = _readJsonFile();
        string memory nameKey = string.concat(".", vm.toString(block.chainid), ".", name);

        if (vm.keyExistsJson(json, nameKey)) {
            bytes memory jsonBytes = vm.parseJson(json, nameKey);
            return abi.decode(jsonBytes, (address));
        }
    }

    // read `name` as Bytes
    function readBytes(string memory name) public view override(IDeployLiteRWJson) returns (bytes memory jsonBytes) {
        require(bytes(name).length > 0, "No name");

        string memory json = _readJsonFile();
        string memory nameKey = string.concat(".", vm.toString(block.chainid), ".", name);

        if (vm.keyExistsJson(json, nameKey)) {
            jsonBytes = vm.parseJson(json, nameKey);
        }
    }

    // read `name` as String
    function readString(string memory name)
        public
        view
        override(IDeployLiteRWJson)
        returns (string memory jsonString)
    {
        bytes memory jsonBytes = readBytes(name);
        jsonString = abi.decode(jsonBytes, (string));
    }

    // read `name` as Bytes32
    function readBytes32(string memory name) public view override(IDeployLiteRWJson) returns (bytes32 jsonBytes32) {
        bytes memory jsonBytes = readBytes(name);
        jsonBytes32 = abi.decode(jsonBytes, (bytes32));
    }

    // read `name` as Uint
    function readUint(string memory name) public view override(IDeployLiteRWJson) returns (uint256) {
        bytes memory jsonBytes = readBytes(name);
        if (jsonBytes.length == 0) return 0;

        string memory jsonString = abi.decode(jsonBytes, (string));
        return _stringToUint(jsonString);
    }

    function removeAddress(string memory name) public override(IDeployLiteRWJson) {
        require(bytes(name).length > 0, "No name");

        // remove address to file only when recording
        if (!(_recording)) return;

        string memory networkKey = string.concat(".", vm.toString(block.chainid));
        string memory nameKey = string.concat(networkKey, ".", name);

        string memory jsonFromFile = _readJsonFile();
        vm.serializeJson("root", jsonFromFile);

        if (vm.keyExistsJson(jsonFromFile, nameKey)) {
            string memory json = _keyDelete(jsonFromFile, networkKey, name);
            vm.writeJson(json, _jsonFile, networkKey);
        }
    }

    function writeAddress(string memory name, address addr) public override(IDeployLiteRWJson) {
        require(bytes(name).length > 0, "No name");

        _addresses[name] = addr;

        // write address to file only when recording
        if (!(_recording)) return;

        string memory networkKey = string.concat(".", vm.toString(block.chainid));
        string memory nameKey = string.concat(networkKey, ".", name);

        string memory jsonFromFile = _readJsonFile();
        string memory jsonNetwork;

        vm.serializeJson("root", jsonFromFile);

        if (vm.keyExistsJson(jsonFromFile, networkKey)) {
            if (vm.keyExistsJson(jsonFromFile, nameKey)) {
                vm.writeJson(vm.toString(addr), _jsonFile, nameKey);
            } else {
                _keyUpdate(jsonFromFile, networkKey, name, vm.toString(addr));
                vm.writeJson(jsonFromFile, _jsonFile);
            }
        } else {
            vm.serializeString("network", "chainName", "");
            jsonNetwork = vm.serializeAddress("network", name, addr);
            string memory jsonRoot = vm.serializeString("root", vm.toString(block.chainid), jsonNetwork);
            vm.writeJson(jsonRoot, _jsonFile);
        }
    }

    function _keyDelete(string memory jsonIn, string memory keyPath, string memory name)
        internal
        returns (string memory jsonOut)
    {
        string memory jsonPath;
        string[] memory names = vm.parseJsonKeys(jsonIn, string.concat(".", keyPath));

        for (uint256 i = 0; i < names.length; i++) {
            if (keccak256(abi.encode(names[i])) == keccak256(abi.encode(name))) continue;

            string memory keyName = string.concat(".", keyPath, ".", names[i]);
            string memory jsonString = vm.parseJsonString(jsonIn, keyName);
            jsonPath = vm.serializeString("pathKey", names[i], jsonString);
        }
        jsonOut = vm.serializeString("pathOut", keyPath, jsonPath);
    }

    function _keyUpdate(string memory jsonIn, string memory keyPath, string memory name, string memory value)
        internal
        returns (string memory jsonOut)
    {
        string memory jsonPath;
        string[] memory names = vm.parseJsonKeys(jsonIn, string.concat(".", keyPath));

        for (uint256 i = 0; i < names.length; i++) {
            string memory keyName = string.concat(".", keyPath, ".", names[i]);
            string memory jsonString = vm.parseJsonString(jsonIn, keyName);
            jsonPath = vm.serializeString("pathKey", names[i], jsonString);
        }
        jsonPath = vm.serializeString("pathKey", name, value);
        jsonOut = vm.serializeString("pathOut", keyPath, jsonPath);
    }

    function _readJsonFile() internal view returns (string memory) {
        try vm.readFile(_jsonFile) returns (string memory jsonFromFile) {
            return jsonFromFile;
        } catch {
            return "{}";
        }
    }
}
