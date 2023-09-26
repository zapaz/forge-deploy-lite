// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../script/ReadWriteJson.s.sol";
import {IDeployLite} from "../script/interfaces/IDeployLite.sol";
import {IUtils} from "../script/interfaces/IUtils.sol";

contract DeployLite is Script, IDeployLite, IUtils, ReadWriteJson {
    address deployer;

    function deploy(string memory name, bool update) public override(IDeployLite) returns (address addr) {
        if (!_existsJsonFile()) _createJsonFile(block.chainid);

        if (deployer == address(0)) deployer = msg.sender;

        addr = readAddress(name);
        uint256 codeDeployedLength = getCodeDeployed(name).length;

        if (isSameDeployed(name)) {
            log4(addr, _stringPad20(name), "Already deployed", _bytesPad5(codeDeployedLength));
        } else {
            if (isDeployed(name)) {
                log4(addr, _stringPad20(name), "Older deployment", _bytesPad5(codeDeployedLength));

                if (!update) return addr;
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

    function log3(address addr, string memory name, string memory description) public view override(IUtils) {
        log4(addr, name, description, "");
    }

    function log4(address addr, string memory name, string memory description, string memory more)
        public
        view
        override(IUtils)
    {
        console.log(addr, _stringPad20(name), _stringPad20(description), _stringPad20(more));
    }

    function getCallerModeName(uint256 callerMode) public pure returns (string memory) {
        require(callerMode < 5, "Unknown mode");
        string[5] memory modes = ["None", "Broadcast", "RecurrentBroadcast", "Prank", "RecurrentPrank"];
        return modes[callerMode];
    }

    function logCallers(string memory label) public {
        (VmSafe.CallerMode callerMode, address msgSender, address txOrigin) = vm.readCallers();
        string memory mode = getCallerModeName(uint256(callerMode));

        if (msgSender == txOrigin) {
            log4(txOrigin, label, "msgSender and txOrigin", mode);
        } else {
            log4(txOrigin, label, "txOrigin", mode);
            log4(msgSender, label, "msgSender", mode);
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

    function setDeployer(address deployer_) public override(IDeployLite) {
        deployer = deployer_;
    }

    function resetDeployer() public {
        deployer = address(0);
    }

    function sliceBytes(bytes calldata data, uint256 start, uint256 end)
        public
        pure
        override(IUtils)
        returns (bytes memory)
    {
        return bytes(data[start:end]);
    }

    function _bytesPad5(uint256 n) internal pure returns (string memory) {
        require(n <= 24_576, "Too big Dragon");
        bytes memory b = new bytes(5);
        b[0] = bytes1(n < 10_000 ? 0x20 : uint8(n / 10_000 % 10) + 0x30);
        b[1] = bytes1(n < 1_000 ? 0x20 : uint8(n / 1_000 % 10) + 0x30);
        b[2] = bytes1(n < 100 ? 0x20 : uint8(n / 100 % 10) + 0x30);
        b[3] = bytes1(n < 10 ? 0x20 : uint8(n / 10 % 10) + 0x30);
        b[4] = bytes1(uint8(n % 10) + 0x30);
        return string.concat(string(b), " bytes");
    }

    function _stringPad20(string memory input) internal pure returns (string memory output) {
        return _stringPad(input, 20);
    }

    function _stringPad(string memory input, uint256 len) internal pure returns (string memory output) {
        bytes memory str = bytes(input);
        while (str.length < len) {
            str = abi.encodePacked(str, " ");
        }
        output = string(str);
    }

    function _getCborLength(bytes memory bytecode) internal view returns (uint16) {
        return bytecode.length < 2 ? 0 : uint16(bytes2(this.sliceBytes(bytecode, bytecode.length - 2, bytecode.length)));
    }

    function _removeDeployedCodeMetadata(bytes memory bytecode) internal view returns (bytes memory) {
        uint256 len = _getCborLength(bytecode);
        return (bytecode.length >= len) ? this.sliceBytes(bytecode, 0, bytecode.length - len) : bytecode;
    }
}
