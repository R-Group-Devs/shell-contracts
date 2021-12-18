//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPersonalizedDescriptor is IERC165 {
    // return a token URI that incorporates unique information about the collection and token owner
    function getTokenURI(address collection, uint256 tokenId, address owner) 
        external
        view
        returns (string memory);
}