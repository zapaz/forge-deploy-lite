// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IDeployLiteRWJson} from "./interfaces/IDeployLiteRWJson.sol";
import {DeployLiteUtils} from "./DeployLiteUtils.s.sol";
import {stdJson} from "forge-std/StdJson.sol";
// import {console} from "forge-std/console.sol";

// Read and Write json file of this format
// {
//   "31337": {
//     "chainName": "local",
//     "Counter": "0x90193C961A926261B756D1E5bb255e67ff9498A1"
//   },
//   "11155111": {
//     "chainName": "sepolia",
//     "Counter_last": "0x34A1D3fff3958843C43aD80F30b94c510645C316"
//   }
// }

contract DeployLiteRWJson is IDeployLiteRWJson, DeployLiteUtils {
    using stdJson for string;

    string constant _LAST = "_last";

    mapping(string => address) internal _addresses;

    string internal _jsonFile = "addresses.json";

    bool internal _recording = true;

    string internal _networkId;
    string internal _networkKey;
    uint256 internal objectKeyIndex;

    constructor() {
        _networkId = vm.toString(block.chainid);
        _networkKey = string.concat(".", _networkId);
    }

    function setJsonFile(string memory jsonFile_) public override(IDeployLiteRWJson) {
        _jsonFile = jsonFile_;
    }

    function setRecording(bool recording_) public override(IDeployLiteRWJson) {
        _recording = recording_;
    }

    // read `name` as Bytes
    function readBytes(string memory name)
        public
        view
        override(IDeployLiteRWJson)
        returns (bytes memory bytesFromJson)
    {
        string memory nameKey = _nameKey(name);
        string memory json = _readJsonFile();

        if (vm.keyExistsJson(json, nameKey)) {
            bytesFromJson = json.parseRaw(nameKey);
        }
    }

    // read `name` as Address
    function _readAddress(string memory name) internal view returns (address addr) {
        string memory nameKey = _nameKey(name);
        string memory json = _readJsonFile();

        // return cached address is exists
        if ((addr = _addresses[name]) != address(0)) return addr;

        if (vm.keyExistsJson(json, nameKey)) {
            addr = json.readAddress(nameKey);
        }
    }

    // read `name_LAST` or `name` as Address
    function readAddress(string memory name) public view returns (address addr) {
        addr = _readAddress(string.concat(name, _LAST));
        if (addr == address(0)) addr = _readAddress(name);
    }

    // read `name` as String
    function readString(string memory name) public view override(IDeployLiteRWJson) returns (string memory str) {
        string memory nameKey = _nameKey(name);
        string memory json = _readJsonFile();

        if (vm.keyExistsJson(json, nameKey)) {
            str = json.readString(nameKey);
        }
    }

    // read `name` as Bytes32
    function readBytes32(string memory name) public view override(IDeployLiteRWJson) returns (bytes32 b32) {
        string memory nameKey = _nameKey(name);
        string memory json = _readJsonFile();

        if (vm.keyExistsJson(json, nameKey)) {
            b32 = json.readBytes32(nameKey);
        }
    }

    // read `name` as Uint
    function readUint(string memory name) public view override(IDeployLiteRWJson) returns (uint256 u256) {
        string memory nameKey = _nameKey(name);
        string memory json = _readJsonFile();

        if (vm.keyExistsJson(json, nameKey)) {
            u256 = json.readUint(nameKey);
        }
    }

    function removeAddress(string memory name) public override(IDeployLiteRWJson) {
        string memory nameKey = _nameKey(name);
        string memory json = _readJsonFile();

        // remove cached address
        _addresses[name] = address(0);

        // remove address from file only when recording
        if (!(_recording)) return;

        if (vm.keyExistsJson(json, nameKey)) {
            string memory jsonNetwork = _keyDelete(json, name);
            jsonNetwork.write(_jsonFile, _networkKey);
        }
    }

    function writeAddress(string memory name, address addr) public override(IDeployLiteRWJson) {
        string memory nameKey = _nameKey(name);
        string memory json = _readJsonFile();

        // set cached address
        _addresses[name] = addr;

        // write address to file only when recording
        if (!(_recording)) return;

        // intialize json network key if not exists
        if (!vm.keyExistsJson(json, _networkKey)) {
            string memory rootKey = _uniqueObjectKey();
            vm.serializeJson(rootKey, json);

            string memory jsonNetwork = vm.serializeString("network", "chainName", "");
            json = vm.serializeString(rootKey, _networkId, jsonNetwork);
            json.write(_jsonFile);
        }

        // check nameKey exists
        if (vm.keyExistsJson(json, nameKey)) {
            // name Key exists: directly update with writeJson function with nameKey
            vm.writeJson(vm.toString(addr), _jsonFile, nameKey);
        } else {
            // name Key not exists: update with specific _keyInsert function
            string memory rootKey = _uniqueObjectKey();
            vm.serializeJson(rootKey, json);

            string memory jsonNetwork = _keyInsert(json, name, addr);
            json = vm.serializeString(rootKey, _networkId, jsonNetwork);
            json.write(_jsonFile);
        }
    }

    function _keyDelete(string memory json, string memory name) internal returns (string memory jsonNetwork) {
        string[] memory names = vm.parseJsonKeys(json, _networkKey);
        string memory jsonNetworkKey = _uniqueObjectKey();

        for (uint256 i = 0; i < names.length; i++) {
            // remove key equal to `name`
            if (_stringEqual(names[i], name)) continue;

            try vm.parseJsonString(json, _nameKey(names[i])) returns (string memory jsonString) {
                jsonNetwork = vm.serializeString(jsonNetworkKey, names[i], jsonString);
            } catch {
                string[] memory jsonStringArray = vm.parseJsonStringArray(json, _nameKey(names[i]));
                jsonNetwork = vm.serializeString(jsonNetworkKey, names[i], jsonStringArray);
            }
        }
    }

    function _keyInsert(string memory json, string memory name, address addr) internal returns (string memory) {
        string[] memory names = vm.parseJsonKeys(json, _networkKey);
        string memory jsonNetworkKey = _uniqueObjectKey();

        for (uint256 i = 0; i < names.length; i++) {
            try vm.parseJsonString(json, _nameKey(names[i])) returns (string memory jsonString) {
                vm.serializeString(jsonNetworkKey, names[i], jsonString);
            } catch {
                string[] memory jsonStringArray = vm.parseJsonStringArray(json, _nameKey(names[i]));
                vm.serializeString(jsonNetworkKey, names[i], jsonStringArray);
            }
        }
        return vm.serializeAddress(jsonNetworkKey, name, addr);
    }

    function _uniqueObjectKey() internal returns (string memory objectKey) {
        objectKey = string.concat("ObjectKey.", vm.toString(++objectKeyIndex));
    }

    function _nameKey(string memory name) internal view returns (string memory) {
        require(bytes(name).length > 0, "No name");

        return string.concat(_networkKey, ".", name);
    }

    function _readJsonFile() internal view returns (string memory) {
        try vm.readFile(_jsonFile) returns (string memory json) {
            return json;
        } catch {
            return "{}";
        }
    }
}
