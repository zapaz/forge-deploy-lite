// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "script/ReadWriteJson.s.sol";

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

    function isSameRunCode(bytes memory code1, bytes memory code2) public view returns (bool) {
        return keccak256(removeDeployedCodeMetadata(code1)) == keccak256(removeDeployedCodeMetadata(code2));
    }

    function getCodeToDeploy(string memory name) public returns (bytes memory codeToDeploy) {
        (,,, codeToDeploy) = _deployData(name);
    }

    function _deployData(string memory name)
        public
        returns (bool deployed, bool sameDeployed, address addr, bytes memory codeToDeploy)
    {
        addr = readAddress(name);
        bytes memory codeDeployed = addr.code;
        deployed = codeDeployed.length > 0;

        codeToDeploy = vm.getDeployedCode(string.concat(name, ".sol:", name));

        sameDeployed = isSameRunCode(codeToDeploy, codeDeployed);
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

    function uintPad5(uint256 n) public pure returns (string memory) {
        require(n <= 24_576, "Too big");
        bytes memory b = new bytes(5);
        b[0] = bytes1(n < 10_000 ? 0x20 : uint8(n / 10_000 % 10) + 0x30);
        b[1] = bytes1(n < 1_000 ? 0x20 : uint8(n / 1_000 % 10) + 0x30);
        b[2] = bytes1(n < 100 ? 0x20 : uint8(n / 100 % 10) + 0x30);
        b[3] = bytes1(n < 10 ? 0x20 : uint8(n / 10 % 10) + 0x30);
        b[4] = bytes1(n < 1 ? 0x20 : uint8(n % 10) + 0x30);
        return string(b);
    }

    function stringPad20(string memory input) public pure returns (string memory output) {
        bytes memory str = bytes(input);
        while (str.length < 20) {
            str = abi.encodePacked(str, " ");
        }
        output = string(str);
    }

    function deploy(string memory name) public returns (address) {
        return deploy(name, true);
    }

    function deploy(string memory name, bool update) public returns (address addr) {
        if (!_existsJsonFile()) _createJsonFile(block.chainid);

        deployer = getDeployer();

        bool deployed;
        bool sameDeployed;
        bytes memory code;
        (deployed, sameDeployed, addr, code) = _deployData(name);

        if (sameDeployed) {
            console.log("%s Existing     %s %s bytes", addr, stringPad20(name), uintPad5(code.length));
        } else {
            if (deployed) {
                console.log("%s Old deploy   %s %s bytes", addr, stringPad20(name), uintPad5(addr.code.length));

                if (!update) return addr;
            }
            console.log("%s Deploying... %s", addr, name);

            string memory deployFunction = string.concat("deploy", name, "()");
            (bool success, bytes memory result) = address(this).call(abi.encodeWithSignature(deployFunction));

            require(success, "deploy call failed");
            (addr) = abi.decode(result, (address));

            writeAddressToCache(name, addr);

            console.log("%s New deploy   %s %s bytes", addr, stringPad20(name), uintPad5(addr.code.length));
        }
    }
}
