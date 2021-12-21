//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IShellFramework.sol";

// All shell erc721s must implement this interface
interface IShellERC721 is IShellFramework, IERC721Upgradeable {
    // token id serial number
    function nextTokenId() external view returns (uint256);

    // Mint a new token. Only callable by engine
    function mint(address to, MintOptions calldata options)
        external
        returns (uint256);

    // need to reconcile collision between non-upgradeable and upgradeable
    // flavors of the openzep interfaces
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(IERC165, IERC165Upgradeable)
        returns (bool);
}
