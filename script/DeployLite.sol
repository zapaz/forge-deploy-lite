// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "script/ReadWriteJson.sol";

contract DeployLite is Script, ReadWriteJson {
    address deployer;

    function sliceBytes(bytes calldata data, uint256 start, uint256 end) public pure returns (bytes memory) {
        return bytes(data[start:end]);
    }

    function getCborLength(bytes memory bytecode) public view returns (uint16) {
        return bytecode.length < 2 ? 0 : uint16(bytes2(this.sliceBytes(bytecode, bytecode.length - 2, bytecode.length)));
    }

    function removeDeployedCodeMetadata(bytes memory bytecode) public view returns (bytes memory) {
        return this.sliceBytes(bytecode, 0, bytecode.length - getCborLength(bytecode));
    }

    function isDeployed(string memory name)
        public
        view
        returns (bool deployed, address addr, bytes memory codeToDeploy)
    {
        addr = readAddress(name);
        bytes memory codeDeployed = addr.code;
        codeToDeploy = vm.getDeployedCode(string.concat(name, ".sol:", name));

        deployed =
            keccak256(removeDeployedCodeMetadata(codeToDeploy)) == keccak256(removeDeployedCodeMetadata(codeDeployed));
    }

    function saveDeployed(string memory name, address addr) public {
        writeAddress(name, addr);
    }

    function getDeployer() public view returns (address) {
        try vm.envAddress("ETH_FROM") returns (address from) {
            return from;
        } catch {
            return msg.sender;
        }
    }

    function deploy(string memory name) public returns (address) {
        if (!existsJsonFile()) createJsonFile();

        deployer = getDeployer();

        (bool deployed, address addr, bytes memory code) = isDeployed(name);

        if (deployed) {
            console.log("%s already deployed at @%s (%s bytes)", name, addr, code.length);
        } else {
            if (addr.code.length > 0) {
                console.log("%s previous deployement at @%s (%s bytes)", name, addr, addr.code.length);
            }
            console.log("%s deploying... (%s bytes)", name, code.length);

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
