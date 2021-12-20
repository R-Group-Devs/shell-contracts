//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICollection} from "../../ICollection.sol";
import {IEngine} from "../../IEngine.sol";

interface ISquadzEngine is IEngine {
    function setDescriptor(ICollection collection, address descriptorAddress, bool admin) external;

    function mint(
        ICollection collection,
        address to,
        bool admin
    ) external returns (uint256);

    function batchMint(
        ICollection collection,
        address[] calldata toAddresses,
        bool[] calldata adminBools
    ) external returns (uint256[] memory);
}