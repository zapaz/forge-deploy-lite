// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {LibString} from "../script/lib/LibString.sol";
import {IReadWriteJson} from "../script/interfaces/IReadWriteJson.sol";

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
contract ReadWriteJson is Script, IReadWriteJson {
    using LibString for string;

    string internal jsonFile = "addresses.json";

    function setJsonFile(string memory jsonFile_) public {
        jsonFile = jsonFile_;
    }

    function readAddress(string memory name) public view returns (address) {
        require(bytes(name).length != 0, "No name");

        string memory json = _readJsonFile();
        string memory nameKey = string.concat(".", vm.toString(block.chainid), ".", name);

        if (vm.keyExists(json, nameKey)) {
            bytes memory jsonBytes = vm.parseJson(json, nameKey);
            return abi.decode(jsonBytes, (address));
        }

        return address(0);
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

        string memory networkKey = string.concat(".", vm.toString(block.chainid));
        string memory nameKey = string.concat(networkKey, ".", name);

        string memory jsonFromFile = _readJsonFile();
        string memory jsonNetwork;
        string memory jsonName;

        vm.serializeJson("root", jsonFromFile);

        if (vm.keyExists(jsonFromFile, networkKey)) {
            if (vm.keyExists(jsonFromFile, nameKey)) {
                vm.writeJson(vm.toString(addr), jsonFile, nameKey);
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
                vm.writeJson(jsonNetwork, jsonFile, networkKey);
            }
        } else {
            vm.serializeString("network", "chainName", "");
            jsonNetwork = vm.serializeAddress("network", name, addr);
            string memory json = vm.serializeString("root", vm.toString(block.chainid), jsonNetwork);
            vm.writeJson(json, jsonFile);
        }
    }

    function _readJsonFile() internal view returns (string memory) {
        try vm.readFile(jsonFile) returns (string memory jsonFromFile) {
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
