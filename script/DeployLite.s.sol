// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "script/ReadWriteJson.s.sol";
import {IDeployLite} from "script/interfaces/IDeployLite.sol";
import {ISliceBytes} from "script/interfaces/ISliceBytes.sol";

contract DeployLite is IDeployLite, ISliceBytes, Script, ReadWriteJson {
    address deployer;

    function deploy(string memory name, bool update) public override(IDeployLite) returns (address addr) {
        if (!_existsJsonFile()) _createJsonFile(block.chainid);

        deployer = getDeployer();
        addr = readAddress(name);
        uint256 codeDeployedLength = getCodeDeployed(name).length;

        if (isSameDeployed(name)) {
            console.log("%s Existing     %s %s bytes", addr, _stringPad20(name), _uintPad5(codeDeployedLength));
        } else {
            if (isDeployed(name)) {
                console.log("%s Old deploy   %s %s bytes", addr, _stringPad20(name), _uintPad5(codeDeployedLength));

                if (!update) return addr;
            }
            console.log("%s Deploying... %s", addr, name);

            string memory deployFunction = string.concat("deploy", name, "()");
            (bool success, bytes memory result) = address(this).call(abi.encodeWithSignature(deployFunction));

            require(success, "deploy call failed");
            (addr) = abi.decode(result, (address));

            writeAddressToCache(name, addr);

            console.log("%s New deploy   %s %s bytes", addr, _stringPad20(name), _uintPad5(addr.code.length));
        }
    }

    function deploy(string memory name) public override(IDeployLite) returns (address) {
        return deploy(name, true);
    }

    function isSameRunCode(bytes memory code1, bytes memory code2) public view override(IDeployLite) returns (bool) {
        return keccak256(_removeDeployedCodeMetadata(code1)) == keccak256(_removeDeployedCodeMetadata(code2));
    }

    function getCodeDeployed(string memory name) public override(IDeployLite) returns (bytes memory) {
        return readAddress(name).code;
    }

    function getCodeToDeploy(string memory name) public view override(IDeployLite) returns (bytes memory) {
        return vm.getDeployedCode(string.concat(name, ".sol:", name));
    }

    function isDeployed(string memory name) public override(IDeployLite) returns (bool) {
        return getCodeDeployed(name).length > 0;
    }

    function isSameDeployed(string memory name) public override(IDeployLite) returns (bool) {
        return isSameRunCode(getCodeToDeploy(name), getCodeDeployed(name));
    }

    // get address if exists, creates a fake one otherwise
    // to not get fake one, use directly readAddress that will return default address(0)
    function getAddress(string memory name) public override(IDeployLite) returns (address addr) {
        addr = readAddress(name);
        if (addr == address(0)) {
            addr = makeAddr(name);
            console.log(addr, "New EOA     ", name);
        } else {
            addr = msg.sender;
            console.log(addr, "Existing    ", name);
        }
    }

    function getDeployer() public view override(IDeployLite) returns (address) {
        try vm.envAddress("ETH_FROM") returns (address from) {
            return from;
        } catch {
            return msg.sender;
        }
    }

    function sliceBytes(bytes calldata data, uint256 start, uint256 end)
        public
        pure
        override(ISliceBytes)
        returns (bytes memory)
    {
        return bytes(data[start:end]);
    }

    function _uintPad5(uint256 n) internal pure returns (string memory) {
        require(n <= 24_576, "Too big Dragon");
        bytes memory b = new bytes(5);
        b[0] = bytes1(n < 10_000 ? 0x20 : uint8(n / 10_000 % 10) + 0x30);
        b[1] = bytes1(n < 1_000 ? 0x20 : uint8(n / 1_000 % 10) + 0x30);
        b[2] = bytes1(n < 100 ? 0x20 : uint8(n / 100 % 10) + 0x30);
        b[3] = bytes1(n < 10 ? 0x20 : uint8(n / 10 % 10) + 0x30);
        b[4] = bytes1(n < 1 ? 0x20 : uint8(n % 10) + 0x30);
        return string(b);
    }

    function _stringPad20(string memory input) internal pure returns (string memory output) {
        bytes memory str = bytes(input);
        while (str.length < 20) {
            str = abi.encodePacked(str, " ");
        }
        output = string(str);
    }

    function _getCborLength(bytes memory bytecode) internal view returns (uint16) {
        return bytecode.length < 2 ? 0 : uint16(bytes2(this.sliceBytes(bytecode, bytecode.length - 2, bytecode.length)));
    }

    function _removeDeployedCodeMetadata(bytes memory bytecode) internal view returns (bytes memory) {
        return this.sliceBytes(bytecode, 0, bytecode.length - _getCborLength(bytecode));
    }
}
