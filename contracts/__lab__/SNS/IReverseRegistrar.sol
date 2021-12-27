//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IReverseRegistrar {
    function node(address) external view virtual returns (bytes32);
}