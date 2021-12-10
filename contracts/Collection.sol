//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC2981.sol";
import "./IEngine.sol";

contract Collection is Ownable, ERC721, IERC2981 {
  IEngine public engine;

  event EngineInstalled(address indexed from, IEngine indexed engine);

  mapping(uint256 => string) public tokenData;

  constructor(string memory name, string memory symbol, IEngine engine_, address owner) ERC721(name, symbol) {
    engine = engine_;
    _transferOwnership(owner);
    _installEngine(engine_);
  }

  // swap out the current engine. Can only be called by owner
  function installEngine(IEngine engine_) external onlyOwner {
    _installEngine(engine_);
  }

  // delegate resolution of tokenURI to currently installed engine
  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return engine.getTokenURI(this, tokenId, tokenData[tokenId]);
  }

  // mint a new token. Can only be called by the currently installed engine
  function mint(address to, uint256 tokenId, string memory data) external {
    require(msg.sender == address(engine), "mint must be called by engine");
    _mint(to, tokenId);
    tokenData[tokenId] = data;
  }

  // delegate resolution of royaltyInfo to the currently installed engine
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
      override external view returns (address receiver, uint256 royaltyAmount) {
    return engine.getRoyaltyInfo(this, tokenId, tokenData[tokenId], salePrice);
  }

  // open zep hook, will be called on all transfers (including mint and burn).
  // Delegates to the currently installed engine, but does not allow breaking
  // token transfer
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) override internal {
    try engine.beforeTokenTransfer(this, from, to, tokenId, tokenData[tokenId]) {
    } catch {
      // engine reverted, but we don't want to block the transfer
    }
  }

  function _installEngine(IEngine engine_) internal {
    engine = engine_;
    emit EngineInstalled(msg.sender, engine_);
  }

}
