//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./ShellFramework.sol";

contract ShellERC721 is ShellFramework, ERC721Upgradeable {
    // for ERC-721s, mint amount must be 1
    error InvalidMintAmount();

    function initialize(
        string calldata name_,
        string calldata symbol_,
        IEngine engine,
        address owner_
    ) external initializer {
        // using the unchained variant since theres no real need to init the
        // erc165 and context stuff from openzep's 721
        __ERC721_init_unchained(name_, symbol_);

        __ShellFramework_init(engine, owner_);
    }

    // ---
    // Standard ERC721 stuff
    // ---

    function name()
        public
        view
        override(IShellFramework, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721Upgradeable.name();
    }

    function symbol()
        public
        view
        override(IShellFramework, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721Upgradeable.symbol();
    }

    // ---
    // Views powered by engine
    // ---

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return getTokenEngine(tokenId).getTokenURI(this, tokenId);
    }

    // ---
    // Framework functionality
    // ---

    // Set the fork of a specific token. Must be token owner
    function forkToken(uint256 tokenId, uint256 forkId) public override {
        if (msg.sender != ownerOf(tokenId)) {
            revert SenderNotTokenOwner();
        }

        _forkToken(tokenId, forkId);
    }

    function forkTokens(uint256[] memory tokenIds, uint256 forkId)
        external
        override
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (msg.sender != ownerOf(tokenIds[i])) {
                revert SenderNotTokenOwner();
            }

            _forkToken(tokenIds[i], forkId);
        }
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
        require(entry.amount == 1, "shell: amount must be 1");
        uint256 tokenId = nextTokenId++;
        _mint(entry.to, tokenId);
        _writeMintData(tokenId, entry);
        return tokenId;
    }

    // ---
    // Introspection
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ShellFramework, ERC721Upgradeable)
        returns (bool)
    {
        return
            ShellFramework.supportsInterface(interfaceId) ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    // ---
    // Wire up the openzep 721 hook to the engine
    // ---

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        getTokenEngine(tokenId).beforeTokenTransfer(
            msg.sender,
            from,
            to,
            tokenId,
            1
        );
    }
}
