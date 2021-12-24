//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./ShellFramework.sol";
import "./IShellERC721.sol";

contract ShellERC721 is ShellFramework, IShellERC721, ERC721Upgradeable {
    uint256 public nextTokenId;

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

        nextTokenId = 1;
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
        return installedEngine.getTokenURI(this, tokenId);
    }

    // ---
    // NFT owner functionality
    // ---

    function installTokenEngine(uint256 tokenId, IEngine engine) external {
        require(msg.sender == ownerOf(tokenId), "shell: not nft owner");
        _installTokenEngine(tokenId, engine);
    }

    // ---
    // Engine functionality
    // ---

    function mint(address to, MintOptions calldata options)
        external
        returns (uint256)
    {
        require(msg.sender == address(installedEngine), "shell: not engine");

        uint256 tokenId = nextTokenId++;
        _mint(to, tokenId);
        _writeMintData(to, tokenId, options);

        return tokenId;
    }

    // ---
    // Introspection
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ShellFramework, IShellERC721, ERC721Upgradeable)
        returns (bool)
    {
        return
            ShellFramework.supportsInterface(interfaceId) ||
            interfaceId == type(IShellERC721).interfaceId ||
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
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        tokenIds[0] = tokenId;
        amounts[0] = 1;
        installedEngine.beforeTokenTransfer(
            this,
            msg.sender,
            from,
            to,
            tokenIds,
            amounts
        );
    }
}
