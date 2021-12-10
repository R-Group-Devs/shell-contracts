//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// base interface all engines must implement
interface IEngine {

  // called by the collection to resolve a response for tokenURI
  function getTokenURI(IERC721 collection, uint256 tokenId)
    external view returns (string memory);

  // called by the collection to response a response for royaltyInfo
  function getRoyaltyInfo(IERC721 collection, uint256 tokenId, uint256 salePrice)
    external view returns (address receiver, uint256 royaltyAmount);

  // called by the collection during a transfer, including mints (from=0) and
  // burns (to=0). Cannot break transfer even in the case of reverting, as the
  // collection will wrap the downstream call in a try/catch
  function beforeTokenTransfer(IERC721 collection, uint256 tokenId, address to, address from)
    external;

}
