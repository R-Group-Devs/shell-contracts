//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./ShellFramework.sol";

contract ShellERC1155 is ShellFramework, ERC1155Upgradeable {
    // cant fork 1155s
    error ForkingNotAllowed();

    string public name;

    string public symbol;

    function initialize(
        string calldata name_,
        string calldata symbol_,
        IEngine engine,
        address owner_
    ) external initializer {
        // intentionally not init-ing anything here from the 1155, only thing it
        // sets is _uri which we arent using

        __ShellFramework_init(engine, owner_);

        name = name_;
        symbol = symbol_;
    }

    // ---
    // Framework functionality
    // ---

    function forkToken(uint256, uint256) public pure override {
        revert ForkingNotAllowed();
    }

    function forkTokens(uint256[] calldata, uint256) external pure override {
        revert ForkingNotAllowed();
    }

    // ---
    // Views powered by engine
    // ---

    function uri(uint256 tokenId) public view override returns (string memory) {
        return getTokenEngine(tokenId).getTokenURI(this, tokenId);
    }

    // ---
    // Engine functionality
    // ---

    function mint(MintEntry calldata entry) external returns (uint256) {
        if (msg.sender != address(getForkEngine(0))) {
            revert SenderNotEngine();
        }

        return _mint(entry);
    }

    function batchMint(MintEntry[] calldata entries)
        external
        returns (uint256[] memory)
    {
        if (msg.sender != address(getForkEngine(0))) {
            revert SenderNotEngine();
        }

        uint256[] memory tokenIds = new uint256[](entries.length);

        for (uint256 i = 0; i < entries.length; i++) {
            tokenIds[i] = _mint(entries[i]);
        }

        return tokenIds;
    }

    function _mint(MintEntry calldata entry) internal returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _mint(entry.to, tokenId, entry.amount, "");
        _writeMintData(tokenId, entry);
        return tokenId;
    }

    // ---
    // Introspection
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ShellFramework, ERC1155Upgradeable)
        returns (bool)
    {
        return
            ShellFramework.supportsInterface(interfaceId) ||
            ERC1155Upgradeable.supportsInterface(interfaceId);
    }

    // ---
    // Wire up the openzep 1155 hook to the engine
    // ---

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            IEngine engine = getTokenEngine(tokenId);
            engine.beforeTokenTransfer(operator, from, to, tokenId, amounts[i]);
        }
    }
}
