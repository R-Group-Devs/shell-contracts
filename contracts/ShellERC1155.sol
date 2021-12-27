//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "./ShellFramework.sol";
import "./IShellERC1155.sol";

contract ShellERC1155 is ShellFramework, IShellERC1155, ERC1155Upgradeable {
    uint256 public nextTokenId;

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
        name = name_;
        symbol = symbol_;

        __ShellFramework_init(engine, owner_);

        nextTokenId = 1;
    }

    // ---
    // Views powered by engine
    // ---

    function uri(uint256 tokenId) public view override returns (string memory) {
        return installedEngine.getTokenURI(this, tokenId);
    }

    // ---
    // NFT owner functionality
    // ---

    function installTokenEngine(uint256, IEngine) external pure {
        revert("shell: cannot install token engine");
    }

    // ---
    // Engine functionality
    // ---

    function mint(MintEntry calldata entry) external returns (uint256) {
        require(msg.sender == address(installedEngine), "shell: not engine");
        return _mint(entry);
    }

    function batchMint(MintEntry[] calldata entries)
        external
        returns (uint256[] memory)
    {
        require(msg.sender == address(installedEngine), "shell: not engine");
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
        override(ShellFramework, IShellERC1155, ERC1155Upgradeable)
        returns (bool)
    {
        return
            ShellFramework.supportsInterface(interfaceId) ||
            interfaceId == type(IShellERC1155).interfaceId ||
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
        installedEngine.beforeTokenTransfer(
            this,
            operator,
            from,
            to,
            ids,
            amounts
        );
    }
}
