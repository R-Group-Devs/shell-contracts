//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReverseRecordsLike {
    function getNames(address[] calldata) external view virtual returns (string[] memory r);
}