//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IShellFramework} from "../../IShellFramework.sol";
import {IEngine} from "../../IEngine.sol";

interface ISquadzEngine is IEngine {
    function setDescriptor(IShellFramework collection, address descriptorAddress, bool admin) external;

    function mint(
        IShellFramework collection,
        address to,
        bool admin
    ) external returns (uint256);

    function batchMint(
        IShellFramework collection,
        address[] calldata toAddresses,
        bool[] calldata adminBools
    ) external returns (uint256[] memory);
}