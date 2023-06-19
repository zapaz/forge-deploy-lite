// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {LibString} from "script/lib/LibString.sol";
import {IReadWriteJson} from "script/interfaces/IReadWriteJson.sol";

contract ReadWriteJson is Script, IReadWriteJson {
    using LibString for string;

    string public jsonFile = "json/addresses.json";

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
        string memory jsonKey = string.concat(".", vm.toString(block.chainid));
        if (bytes(name).length > 0) jsonKey = string.concat(jsonKey, ".", name);

        vm.writeJson(vm.toString(addr), jsonFile, jsonKey);
        if (addr != readAddress(name)) {
            _writeJsonWithReplace(name, vm.toString(addr));
        }
    }

    function _writeJsonWithReplace(string memory key, string memory value) internal {
        string memory search = string.concat("\"", vm.toString(block.chainid), "\": {");
        string memory replacement = string.concat(search, "\n    \"", key, "\": \"", value, "\",");

        string memory json = vm.readFile(jsonFile);
        vm.writeFile(jsonFile, json.replace(search, replacement));
    }

    function _stringEqual(string memory string1, string memory string2) internal pure returns (bool) {
        return keccak256(bytes(string1)) == keccak256(bytes(string2));
    }
}
