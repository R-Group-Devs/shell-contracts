//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INameResolverLike {
    function name(bytes32 node) external view returns (string memory);
}