//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRegistrarLike {
    function resolver(bytes32 node) external view returns (address);
}