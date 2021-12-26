//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IShellFramework.sol";

// All shell erc721s must implement this interface
// interaceId = 0x01ffc9a7
interface IShellERC721 is IShellFramework, IERC721Upgradeable {
    // need to reconcile collision between non-upgradeable and upgradeable
    // flavors of the openzep interfaces
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(IERC165, IERC165Upgradeable)
        returns (bool);
}
