// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "script/ReadWriteJson.sol";

contract DeployLite is Script, ReadWriteJson {
    // script storage lost after each run!
    mapping(address => bool) done;

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

    function isSameRunCode(bytes memory code1, bytes memory code2) public view returns (bool) {
        return keccak256(removeDeployedCodeMetadata(code1)) == keccak256(removeDeployedCodeMetadata(code2));
    }

    function isDeployed(string memory name)
        public
        view
        returns (bool deployed, address addr, bytes memory codeToDeploy)
    {
        addr = readAddress(name);
        bytes memory codeDeployed = addr.code;
        codeToDeploy = vm.getDeployedCode(string.concat(name, ".sol:", name));

        deployed = isSameRunCode(codeToDeploy, codeDeployed);
    }

    function saveDeployed(string memory name, address addr) public {
        writeAddress(name, addr);
    }

    // get address if exists, creates a fake one otherwise
    // to not get fake one, use directly readAddress that will return default address(0)
    function getAddress(string memory name) public returns (address addr) {
        addr = readAddress(name);
        if (addr == address(0)) {
            addr = makeAddr(name);
            console.log(addr, "New EOA     ", name);
        } else {
            addr = msg.sender;
            console.log(addr, "Existing    ", name);
        }
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

        if (done[addr]) return addr;

        if (deployed) {
            console.log("%s Existing     %s (%s bytes)", addr, name, code.length);
        } else {
            if (addr.code.length > 0) {
                console.log("%s Old deploy %s (%s bytes)", addr, name, addr.code.length);
            }
            console.log("%s Deploying... %s", addr, name);

            string memory deployFunction = string.concat("deploy", name, "()");
            (bool success, bytes memory result) = address(this).call(abi.encodeWithSignature(deployFunction));

            require(success, "deploy call failed");
            (addr) = abi.decode(result, (address));

            saveDeployed(name, addr);
            console.log("%s New deploy   %s (%s bytes)", addr, name, addr.code.length);

            done[addr] = true;
        }

        return addr;
    }
}
