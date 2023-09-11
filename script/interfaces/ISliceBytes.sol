// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISliceBytes {
    function sliceBytes(bytes calldata data, uint256 start, uint256 end) external pure returns (bytes memory);
}
