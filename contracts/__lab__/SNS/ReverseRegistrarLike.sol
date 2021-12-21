//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReverseRegistrarLike {
    function node(address) public virtual returns (bytes32);
}