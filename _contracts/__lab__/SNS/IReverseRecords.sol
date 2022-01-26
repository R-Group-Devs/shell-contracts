//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IReverseRecords {
    function getNames(address[] calldata) external view virtual returns (string[] memory r);
}