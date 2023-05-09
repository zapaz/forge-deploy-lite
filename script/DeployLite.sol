// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract DeployLite is Script {
    string constant ADDRESSES_FILE = "addresses.json";
    address deployer;
    
    function writeAddress(string memory name, address addr) public {
        string memory path = string.concat(".", vm.toString(block.chainid), ".", name);
        vm.writeJson(vm.toString(addr), ADDRESSES_FILE, path);
    }

    function readAddress(string memory name) public view returns (address) {
        string memory jsonFile = vm.readFile(ADDRESSES_FILE);
        string memory path = string.concat(".", vm.toString(block.chainid), ".", name);

        return abi.decode(vm.parseJson(jsonFile, path), (address));
    }

    function isDeployed(string memory name) public view returns (bool deployed, address addr, bytes memory code) {
        addr = readAddress(name);
        code = vm.getDeployedCode(string.concat(name, ".sol:", name));
        deployed = (keccak256(addr.code) == keccak256(code));
    }

    function saveDeployed(string memory name, address addr) public {
        writeAddress(name, addr);
    }

    function deploy(string memory name) public returns (address) {
        deployer = msg.sender;

        (bool deployed, address addr, bytes memory code) = isDeployed(name);

        if (deployed) {
            console.log("%s already deployed at @%s (%s bytes)", name, addr, code.length);
        } else {
            if (addr.code.length > 0) {
                console.log("%s previous deployement at @%s (%s bytes)", name, addr, addr.code.length);
            }
            console.log("%s deploying... (%s bytes)", name, code.length);
            // console.logBytes(code);

            string memory deployFunction = string.concat("deploy", name, "()");
            (bool success, bytes memory result) = address(this).call(abi.encodeWithSignature(deployFunction));

            require(success, "deploy call failed");
            (addr) = abi.decode(result, (address));

            saveDeployed(name, addr);
            console.log("%s deployed to @%s (%s bytes)", name, addr, addr.code.length);
        }

        return addr;
    }
}
