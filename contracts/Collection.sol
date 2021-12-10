//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IERC2981.sol";
import "./IEngine.sol";

contract Collection is ERC721, IERC2981 {
  IEngine public engine;

  mapping(uint256 => string) public tokenData;

  constructor(string memory name, string memory symbol, IEngine engine_) ERC721(name, symbol) {
    engine = engine_;
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return engine.getTokenURI(this, tokenId, tokenData[tokenId]);
  }

  function mint(address to, uint256 tokenId, string memory data) external {
    require(msg.sender == address(engine), "mint must be called by engine");
    _mint(to, tokenId);
    tokenData[tokenId] = data;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
      override external view returns (address receiver, uint256 royaltyAmount) {
    return engine.getRoyaltyInfo(this, tokenId, tokenData[tokenId], salePrice);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) override internal {
    try engine.beforeTokenTransfer(this, from, to, tokenId, tokenData[tokenId]) {
    } catch {
      // engine reverted, but we don't want to block the transfer
    }
  }
}
