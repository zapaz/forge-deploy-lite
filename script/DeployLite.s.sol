// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

import {IDeployLite} from "./interfaces/IDeployLite.sol";
import {DeployLiteRWJson} from "./DeployLiteRWJson.s.sol";

contract DeployLite is Script, IDeployLite, DeployLiteRWJson {
    address deployer;

    function deploy(string memory name) public override(IDeployLite) returns (address) {
        return deploy(name, true);
    }

    function deploy(string memory name, bool forceUpdate) public override(IDeployLite) returns (address addr) {
        if (deployer == address(0)) deployer = msg.sender;

        addr = readAddress(name);
        uint256 codeDeployedLength = getCodeDeployed(name).length;

        if (isSameDeployed(name)) {
            log4(addr, _stringPad20(name), "Already deployed", _bytesPad5(codeDeployedLength));
        } else {
            if (isDeployed(name)) {
                log4(addr, _stringPad20(name), "Older deployment", _bytesPad5(codeDeployedLength));

                if (!forceUpdate) return addr;
            }
            log4(address(0), name, "Deploying...", "");

            string memory deployFunction = string.concat("deploy", name, "()");
            (bool success, bytes memory result) = address(this).call(abi.encodeWithSignature(deployFunction));

            require(success, "deploy call failed");
            (addr) = abi.decode(result, (address));

            writeAddress(name, addr);

            log4(addr, _stringPad20(name), "New deployment", _bytesPad5(addr.code.length));
        }
    }

    function getAddress(string memory name) public override(IDeployLite) returns (address addr) {
        addr = readAddress(name);

        if (addr == address(0)) {
            addr = makeAddr(name);
            writeAddress(name, addr);
            log4(addr, name, "New EOA", "");
        } else {
            log4(addr, name, "Existing", "");
        }
    }

    function isSameRunCode(bytes memory code1, bytes memory code2) public view override(IDeployLite) returns (bool) {
        return keccak256(_removeDeployedCodeMetadata(code1)) == keccak256(_removeDeployedCodeMetadata(code2));
    }

    function getCodeDeployed(string memory name) public view override(IDeployLite) returns (bytes memory) {
        return readAddress(name).code;
    }

    function getCodeToDeploy(string memory name) public view override(IDeployLite) returns (bytes memory) {
        return vm.getDeployedCode(string.concat(name, ".sol:", name));
    }

    function isDeployed(string memory name) public view override(IDeployLite) returns (bool) {
        return getCodeDeployed(name).length > 0;
    }

    function isSameDeployed(string memory name) public view override(IDeployLite) returns (bool) {
        return isSameRunCode(getCodeToDeploy(name), getCodeDeployed(name));
    }

    function setDeployer(address deployer_) public override(IDeployLite) {
        deployer = deployer_;
    }

    function resetDeployer() public {
        deployer = address(0);
    }

    function _getCborLength(bytes memory bytecode) internal view returns (uint16) {
        return bytecode.length < 2 ? 0 : uint16(bytes2(this.sliceBytes(bytecode, bytecode.length - 2, bytecode.length)));
    }

    function _removeDeployedCodeMetadata(bytes memory bytecode) internal view returns (bytes memory) {
        uint256 len = _getCborLength(bytecode);
        return (bytecode.length >= len) ? this.sliceBytes(bytecode, 0, bytecode.length - len) : bytecode;
    }
}
