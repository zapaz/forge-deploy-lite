// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {LibString} from "script/lib/LibString.sol";
import {IReadWriteJson} from "script/interfaces/IReadWriteJson.sol";

contract ReadWriteJson is Script, IReadWriteJson {
    using LibString for string;

    string public jsonFile = "addresses.json";

    function setJsonFile(string memory jsonFile_) public override(IReadWriteJson) {
        jsonFile = jsonFile_;
    }

    function readAddress(string memory name) public view override(IReadWriteJson) returns (address) {
        string memory json = vm.readFile(jsonFile);
        string memory jsonKey = string.concat(".", vm.toString(block.chainid));
        if (bytes(name).length > 0) jsonKey = string.concat(jsonKey, ".", name);

        return abi.decode(vm.parseJson(json, jsonKey), (address));
    }

    function writeAddress(string memory name, address addr) public override(IReadWriteJson) {
        if (!existsJsonFile()) createJsonFile();
        if (!existsJsonNetwork()) createJsonNetwork();

        string memory jsonKey = string.concat(".", vm.toString(block.chainid));
        if (bytes(name).length > 0) jsonKey = string.concat(jsonKey, ".", name);

        vm.writeJson(vm.toString(addr), jsonFile, jsonKey);
        if (addr != readAddress(name)) {
            createJsonAddress(name, addr);
        }
    }

    function createJsonAddress(string memory name, address addr) public {
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
        string memory search = string.concat("\"", vm.toString(block.chainid), "\": {");

        // "31337": {
        //     "name": "0x..."
        string memory replacement = string.concat(search, "\n    \"", name, "\": \"", vm.toString(addr), "\",");

        vm.writeFile(jsonFile, vm.readFile(jsonFile).replace(search, replacement));
    }

    function createJsonFile() public {
        // =>
        // {
        //   "31337": {
        //     "chainName": ""
        //   }
        // }
        string memory jsonNetworkEmpty = string.concat("{\n  \"", vm.toString(block.chainid), "\": {\n  \"chainName\": \"\"}\n}");

        vm.writeFile(jsonFile, jsonNetworkEmpty);
    }

    function createJsonNetwork() public {
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
        string memory replacement = string.concat("{\n  \"", vm.toString(block.chainid), "\": {\n  \"chainName\": \"\"},");

        vm.writeFile(jsonFile, vm.readFile(jsonFile).replace(search, replacement));
    }

    function existsJsonFile() public view returns (bool) {
        try vm.readFile(jsonFile) returns (string memory) {
            return true;
        } catch {
            return false;
        }
    }

    function existsJsonNetwork() public view returns (bool) {
        if (!existsJsonFile()) return false;

        string memory json = vm.readFile(jsonFile);
        string memory jsonKey = string.concat(".", vm.toString(block.chainid));

        return !bytesEqual(vm.parseJson(json, jsonKey), abi.encode(""));
    }

    function bytesEqual(bytes memory b1, bytes memory b2) internal pure returns (bool) {
        return keccak256(b1) == keccak256(b2);
    }

    function stringEqual(string memory s1, string memory s2) internal pure returns (bool) {
        return bytesEqual(bytes(s1), bytes(s2));
    }
}
