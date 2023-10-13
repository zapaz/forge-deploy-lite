// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, VmSafe, console} from "forge-std/Script.sol";
import {LibString} from "../script/lib/LibString.sol";
import {IDeployLiteRWJson} from "../script/interfaces/IDeployLiteRWJson.sol";

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
contract DeployLiteRWJson is Script, IDeployLiteRWJson {
    using LibString for string;

    mapping(string => address) internal _addresses;

    string internal _jsonFile = "addresses.json";

    bool internal _recording = true;

    function setJsonFile(string memory jsonFile_) public {
        _jsonFile = jsonFile_;
    }

    function setRecording(bool recording_) public {
        _recording = recording_;
    }

    function readAddress(string memory name) public view returns (address addr) {
        require(bytes(name).length != 0, "No name");

        if ((addr = _addresses[name]) != address(0)) return addr;

        string memory json = _readJsonFile();
        string memory nameKey = string.concat(".", vm.toString(block.chainid), ".", name);

        if (vm.keyExists(json, nameKey)) {
            bytes memory jsonBytes = vm.parseJson(json, nameKey);
            return abi.decode(jsonBytes, (address));
        }
    }

    function readString(string memory name) public view returns (string memory) {
        console.log("readString", name);
        require(bytes(name).length != 0, "No name");

        string memory json = _readJsonFile();
        string memory nameKey = string.concat(".", vm.toString(block.chainid), ".", name);

        if (vm.keyExists(json, nameKey)) {
            bytes memory jsonBytes = vm.parseJson(json, nameKey);
            return abi.decode(jsonBytes, (string));
        }

        return "";
    }

    function writeAddress(string memory name, address addr) public {
        require(bytes(name).length != 0, "No name");

        _addresses[name] = addr;

        // write address to file only when recording
        if (!(_recording)) return;

        string memory networkKey = string.concat(".", vm.toString(block.chainid));
        string memory nameKey = string.concat(networkKey, ".", name);

        string memory jsonFromFile = _readJsonFile();
        string memory jsonNetwork;

        vm.serializeJson("root", jsonFromFile);

        if (vm.keyExists(jsonFromFile, networkKey)) {
            if (vm.keyExists(jsonFromFile, nameKey)) {
                vm.writeJson(vm.toString(addr), _jsonFile, nameKey);
            } else {
                string[] memory keys = vm.parseJsonKeys(jsonFromFile, networkKey);

                for (uint256 i = 0; i < keys.length; i++) {
                    string memory keyName = keys[i];
                    bytes memory jsonBytes = vm.parseJson(jsonFromFile, string.concat(networkKey, ".", keyName));
                    if (_stringEqual(keyName, "chainName")) {
                        string memory str = abi.decode(jsonBytes, (string));
                        vm.serializeString("network", keyName, str);
                    } else {
                        address keyAddr = abi.decode(jsonBytes, (address));
                        vm.serializeAddress("network", keyName, keyAddr);
                    }
                }
                jsonNetwork = vm.serializeAddress("network", name, addr);
                vm.writeJson(jsonNetwork, _jsonFile, networkKey);
            }
        } else {
            vm.serializeString("network", "chainName", "");
            jsonNetwork = vm.serializeAddress("network", name, addr);
            string memory json = vm.serializeString("root", vm.toString(block.chainid), jsonNetwork);
            vm.writeJson(json, _jsonFile);
        }
    }

    function _readJsonFile() internal view returns (string memory) {
        try vm.readFile(_jsonFile) returns (string memory jsonFromFile) {
            return jsonFromFile;
        } catch {
            return "{}";
        }
    }

    function _bytesEqual(bytes memory b1, bytes memory b2) internal pure returns (bool) {
        return keccak256(b1) == keccak256(b2);
    }

    function _stringEqual(string memory s1, string memory s2) internal pure returns (bool) {
        return _bytesEqual(bytes(s1), bytes(s2));
    }
}
