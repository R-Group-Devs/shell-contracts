//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IShellERC721} from "../../IShellERC721.sol";
import {IEngine} from "../../IEngine.sol";

interface ISquadzEngine is IEngine {
    function setDescriptor(IShellERC721 collection, address descriptorAddress, bool admin) external;

    function mint(
        IShellERC721 collection,
        address to,
        bool admin
    ) external returns (uint256);

    function batchMint(
        IShellERC721 collection,
        address[] calldata toAddresses,
        bool[] calldata adminBools
    ) external returns (uint256[] memory);
}