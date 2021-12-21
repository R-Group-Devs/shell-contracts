//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract NameResolverLike {
    function name(bytes32) external view virtual returns (string memory);
}