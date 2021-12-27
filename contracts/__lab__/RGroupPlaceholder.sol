//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Base64.sol";
import "../IEngine.sol";
import "../IShellFramework.sol";
import "../IShellERC721.sol";
import "../engines/BeforeTokenTransferNopEngine.sol";
import "../engines/NoRoyaltiesEngine.sol";
import "../engines/OnChainMetadataEngine.sol";

contract RGroupPlaceholder is
    IEngine,
    BeforeTokenTransferNopEngine,
    NoRoyaltiesEngine,
    OnChainMetadataEngine
{
    using Strings for uint256;

    function getEngineName() external pure returns (string memory) {
        return "r-group-placeholder";
    }

    function mint(
        IShellERC721 collection,
        string calldata name_,
        string calldata bio
    ) external returns (uint256) {
        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](0);

        uint256 tokenId = collection.mint(
            MintEntry({
                to: msg.sender,
                amount: 1,
                options: MintOptions({
                    storeEngine: true,
                    storeMintedTo: true,
                    storeTimestamp: true,
                    storeBlockNumber: true,
                    stringData: stringData,
                    intData: intData
                })
            })
        );

        updateInfo(collection, tokenId, name_, bio);

        return tokenId;
    }

    function updateInfo(
        IShellFramework collection,
        uint256 tokenId,
        string calldata name_,
        string calldata bio
    ) public {
        collection.writeTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name",
            name_
        );
        collection.writeTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "bio",
            bio
        );
    }

    function _computeName(IShellFramework nft, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        string memory name_ = nft.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        return string(abi.encodePacked("R Group: ", name_));
    }

    function _computeDescription(IShellFramework nft, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        string memory name_ = nft.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        string memory bio = nft.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "bio"
        );
        uint256 mintedTo = nft.readTokenInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "mintedTo"
        );
        uint256 timestamp = nft.readTokenInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "timestamp"
        );

        return
            string(
                abi.encodePacked(
                    "R Group Membership NFT. \\n\\nMember: ",
                    name_,
                    " \\n\\n",
                    bio,
                    " \\n\\nThis membership NFT is only valid if held by ",
                    mintedTo.toHexString(20),
                    " \\n\\nMinted at timestamp ",
                    timestamp.toString(),
                    ".\\n\\n Token ID #",
                    tokenId.toString(),
                    ".\\n\\n Powered by https://heyshell.xyz"
                )
            );
    }

    function _computeImageUri(IShellFramework, uint256)
        internal
        pure
        override
        returns (string memory)
    {
        return
            "https://ipfs.hypervibes.xyz/ipfs/QmXuSWsCCEmNcuugzoNrFBYYCtQoJjKM4qyoeyvbVa8z4Z";
    }

    function _computeExternalUrl(IShellFramework, uint256)
        internal
        pure
        override
        returns (string memory)
    {
        return "https://twitter.com/raribledao";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IEngine).interfaceId;
    }

    function afterInstallEngine(IShellFramework collection) external view {
        require(
            collection.supportsInterface(type(IShellERC721).interfaceId),
            "must implement IShellERC721"
        );
    }

    function afterInstallEngine(IShellFramework collection, uint256)
        external
        view
    {
        require(
            collection.supportsInterface(type(IShellERC721).interfaceId),
            "must implement IShellERC721"
        );
    }
}
