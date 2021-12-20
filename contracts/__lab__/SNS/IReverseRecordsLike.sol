//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReverseRecordsLike {
    function getNames(address[] calldata addresses) external view returns (string[] memory r);
}