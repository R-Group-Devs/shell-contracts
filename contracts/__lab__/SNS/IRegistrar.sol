//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IRegistrar {
    function resolver(bytes32) external view virtual returns (address);
}