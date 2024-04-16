// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDeployLiteRWJson} from "./interfaces/IDeployLiteRWJson.sol";
import {DeployLiteUtils} from "./DeployLiteUtils.s.sol";

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

    function setJsonFile(string memory jsonFile_) public {
        _jsonFile = jsonFile_;
    }

    function setRecording(bool recording_) public {
        _recording = recording_;
    }

    function readAddress(string memory name) public view returns (address addr) {
        addr = _readAddress(string.concat(name, _LAST));
        if (addr == address(0)) addr = _readAddress(name);
    }

    function _readAddress(string memory name) public view returns (address addr) {
        require(bytes(name).length > 0, "No name");

        if ((addr = _addresses[name]) != address(0)) return addr;

        string memory json = _readJsonFile();
        string memory nameKey = string.concat(".", vm.toString(block.chainid), ".", name);

        if (vm.keyExistsJson(json, nameKey)) {
            bytes memory jsonBytes = vm.parseJson(json, nameKey);
            return abi.decode(jsonBytes, (address));
        }
    }

    function readString(string memory name) public view returns (string memory) {
        require(bytes(name).length > 0, "No name");

        string memory json = _readJsonFile();
        string memory nameKey = string.concat(".", vm.toString(block.chainid), ".", name);

        if (vm.keyExistsJson(json, nameKey)) {
            bytes memory jsonBytes = vm.parseJson(json, nameKey);
            return abi.decode(jsonBytes, (string));
        }

        return "";
    }

    function readBytes32(string memory name) public view returns (bytes32) {
        require(bytes(name).length > 0, "No name");

        string memory json = _readJsonFile();
        string memory nameKey = string.concat(".", vm.toString(block.chainid), ".", name);

        if (vm.keyExistsJson(json, nameKey)) {
            bytes memory jsonBytes = vm.parseJson(json, nameKey);
            return abi.decode(jsonBytes, (bytes32));
        }

        return "";
    }

    function getAddress(string memory name) public returns (address addr) {
        addr = readAddress(name);

        if (addr == address(0)) {
            addr = makeAddr(name);
            writeAddress(name, addr);
            log4(addr, name, "New EOA", "");
        } else {
            log4(addr, name, "Existing", "");
        }
    }

    function removeAddress(string memory name) public {
        require(bytes(name).length > 0, "No name");

        // remove address to file only when recording
        if (!(_recording)) return;

        string memory networkKey = string.concat(".", vm.toString(block.chainid));
        string memory nameKey = string.concat(networkKey, ".", name);

        string memory jsonFromFile = _readJsonFile();
        vm.serializeJson("root", jsonFromFile);

        if (vm.keyExistsJson(jsonFromFile, nameKey)) {
            string memory jsonNetwork = _jsonToObject(jsonFromFile, networkKey, name, true);
            vm.writeJson(jsonNetwork, _jsonFile, networkKey);
        }
    }

    function writeAddress(string memory name, address addr) public {
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
                _jsonToObject(jsonFromFile, networkKey, name, false);

                jsonNetwork = vm.serializeAddress(string.concat(networkKey, name), name, addr);
                vm.writeJson(jsonNetwork, _jsonFile, networkKey);
            }
        } else {
            vm.serializeString("network", "chainName", "");
            jsonNetwork = vm.serializeAddress("network", name, addr);
            string memory jsonRoot = vm.serializeString("root", vm.toString(block.chainid), jsonNetwork);
            vm.writeJson(jsonRoot, _jsonFile);
        }
    }

    function _jsonToObject(string memory json, string memory objectKey, string memory name, bool remove)
        internal
        returns (string memory jsonObject)
    {
        string[] memory keys = vm.parseJsonKeys(json, objectKey);
        string memory randomKey = string.concat(objectKey, name);

        for (uint256 i = 0; i < keys.length; i++) {
            string memory keyName = keys[i];
            if (remove && keccak256(abi.encode(keyName)) == keccak256(abi.encode(name))) continue;

            bytes memory jsonBytes = vm.parseJson(json, string.concat(objectKey, ".", keyName));

            if (jsonBytes.length == 32) {
                // value can be address or bytes32
                if (uint256(bytes32(jsonBytes)) < (1 << 160)) {
                    // value maybe address
                    address addressValue = abi.decode(jsonBytes, (address));
                    jsonObject = vm.serializeAddress(randomKey, keyName, addressValue);
                } else {
                    // value maybe bytes32
                    bytes32 bytes32Value = abi.decode(jsonBytes, (bytes32));
                    jsonObject = vm.serializeBytes32(randomKey, keyName, bytes32Value);
                }
            } else {
                // value maybe string
                string memory stringValue = abi.decode(jsonBytes, (string));
                jsonObject = vm.serializeString(randomKey, keyName, stringValue);
            }
        }
    }

    function _readJsonFile() internal view returns (string memory) {
        try vm.readFile(_jsonFile) returns (string memory jsonFromFile) {
            return jsonFromFile;
        } catch {
            return "{}";
        }
    }
}
