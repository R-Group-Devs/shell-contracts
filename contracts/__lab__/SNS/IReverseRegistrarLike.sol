//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReverseRegistrarLike {
    function node(address addr) external view returns (bytes32);
}