//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./IShellFramework.sol";

// All shell erc721s must implement this interface
interface IShellERC1155 is IShellFramework, IERC1155Upgradeable {
    // need to reconcile collision between non-upgradeable and upgradeable
    // flavors of the openzep interfaces
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(IERC165, IERC165Upgradeable)
        returns (bool);
}
