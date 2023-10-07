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
// Add the ability to write a non-existing field to standard stdJon library
// forge script : cheatcodes used, no gas optimization needed
contract ReadWriteJson is Script, IReadWriteJson {
    using LibString for string;

    // save already resolved addresses in storage (script storage is ephemere)
    mapping(uint256 => mapping(string => address)) addresses;
    string[] names;

    string internal jsonFile = "addresses.json";

    function setJsonFile(string memory jsonFile_) public override(IReadWriteJson) {
        jsonFile = jsonFile_;
    }

    function readAddress(string memory name) public view override(IReadWriteJson) returns (address addr) {
        require(bytes(name).length != 0, "No name");
        if ((addr = addresses[block.chainid][name]) != address(0)) return addr;

        if (_existsJsonFile() && _existsJsonNetwork(block.chainid)) {
            addr = _readAddress(block.chainid, name);
        }
    }

    function writeAddress(string memory name, address addr) public override(IReadWriteJson) {
        require(bytes(name).length != 0, "No name");

        if (!_existsJsonFile()) _createJsonFile(block.chainid);
        if (!_existsJsonNetwork(block.chainid)) _createJsonNetwork(block.chainid);

        _writeAddress(block.chainid, name, addr);
    }

    function _writeAddresses() internal {
        for (uint256 index; index < names.length; index++) {
            string memory name = names[index];
            _writeAddress(block.chainid, name, addresses[block.chainid][name]);
        }
    }

    function _writeAddress(uint256 chainId, string memory name, address addr) internal {
        string memory jsonKey = string.concat(".", vm.toString(chainId), ".", name);

        vm.writeJson(vm.toString(addr), jsonFile, jsonKey);
        if (addr != _readAddress(chainId, name)) {
            _createJsonAddress(chainId, name, addr);
        }

        _writeAddressToCache(name, addr);
    }

    function _writeAddressToCache(string memory name, address addr) internal {
        names.push(name);
        addresses[block.chainid][name] = addr;
    }

    function _readAddress(uint256 chainId, string memory name) internal view returns (address addr) {
        string memory json = vm.readFile(jsonFile);
        string memory jsonKey = string.concat(".", vm.toString(chainId), ".", name);

        bytes memory jsonBytes = vm.parseJson(json, jsonKey);
        if (_bytesEqual(jsonBytes, "")) {
            return address(0);
        } else {
            return abi.decode(jsonBytes, (address));
        }
    }

    function _cacheAddresses(uint256 chainId) public {
        string[] memory chainNames = _readJsonNetwork(chainId);

        for (uint256 index; index < chainNames.length; index++) {
            string memory name = chainNames[index];
            address addr = readAddress(name);

            names.push(name);
            addresses[chainId][name] = addr;
        }
    }

    function _createJsonAddress(uint256 chainId, string memory name, address addr) internal {
        // {
        //   "31337": {
        //     "chainName: ""
        //   }
        // }
        // =>
        // {
        //   "31337": {
        //     "chainName: ""
        //     "name": "0x..."
        //   }
        // }

        // "31337": {
        string memory search = string.concat("\"", vm.toString(chainId), "\": {");

        // "31337": {
        //     "name": "0x..."
        string memory replacement = string.concat(search, "\n    \"", name, "\": \"", vm.toString(addr), "\",");

        vm.writeFile(jsonFile, vm.readFile(jsonFile).replace(search, replacement));
    }

    function _existsJsonFile() internal view returns (bool) {
        try vm.readFile(jsonFile) returns (string memory) {
            return true;
        } catch {
            return false;
        }
    }

    function _existsJsonNetwork(uint256 chainId) internal view returns (bool) {
        if (!_existsJsonFile()) return false;

        string memory json = vm.readFile(jsonFile);
        string memory jsonKey = string.concat(".", vm.toString(chainId));

        try vm.parseJsonKeys(json, jsonKey) returns (string[] memory) {
            return true;
        } catch {
            return false;
        }
    }

    function _readJsonNetwork(uint256 chainId) internal view returns (string[] memory chainNames) {
        if (_existsJsonFile()) {
            string memory json = vm.readFile(jsonFile);
            string memory jsonKey = string.concat(".", vm.toString(chainId));

            try vm.parseJsonKeys(json, jsonKey) returns (string[] memory jsonKeys) {
                chainNames = jsonKeys;
            } catch {}
        }
    }

    function _createJsonFile(uint256 chainId) internal {
        // =>
        // {
        //   "31337": {
        //     "chainName": ""
        //   }
        // }
        string memory jsonNetworkEmpty =
            string.concat("{\n  \"", vm.toString(chainId), "\": {\n    \"chainName\": \"\"\n  }\n}");

        vm.writeFile(jsonFile, jsonNetworkEmpty);
    }

    function _createJsonNetwork(uint256 chainId) internal {
        // {
        //   "1": {}
        // }
        //
        // =>
        //
        // {
        //   "31337": {
        //     "chainName": ""
        //   },
        //   "1": {}
        // }

        // {
        string memory search = "{";

        // {
        //   "31337": {
        //   },
        string memory replacement = string.concat("{\n  \"", vm.toString(chainId), "\": {\n  \"chainName\": \"\"},");

        vm.writeFile(jsonFile, vm.readFile(jsonFile).replace(search, replacement));
    }

    function _bytesEqual(bytes memory b1, bytes memory b2) internal pure returns (bool) {
        return keccak256(b1) == keccak256(b2);
    }

    function _stringEqual(string memory s1, string memory s2) internal pure returns (bool) {
        return _bytesEqual(bytes(s1), bytes(s2));
    }
}
