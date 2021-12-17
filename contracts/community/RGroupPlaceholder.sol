//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../libraries/Base64.sol";
import "../libraries/HexStrings.sol";
import "../IEngine.sol";
import "../ICollection.sol";
import "../engines/BeforeTokenTransferNopEngine.sol";
import "../engines/NoRoyaltiesEngine.sol";
import "../engines/OnChainMetadataEngine.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RGroupPlaceholder is
    IEngine,
    BeforeTokenTransferNopEngine,
    NoRoyaltiesEngine,
    OnChainMetadataEngine
{
    using Strings for uint256;

    function name() external pure returns (string memory) {
        return "R Group Membership";
    }

    function mint(
        ICollection collection,
        string calldata name_,
        string calldata bio
    ) external returns (uint256) {
        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](0);

        uint256 tokenId = collection.mint(
            msg.sender,
            MintOptions({
                storeEngine: true,
                storeMintedTo: true,
                storeMintedBy: true,
                storeTimestamp: true,
                storeBlockNumber: true,
                stringData: stringData,
                intData: intData
            })
        );

        updateInfo(collection, tokenId, name_, bio);

        return tokenId;
    }

    function updateInfo(
        ICollection collection,
        uint256 tokenId,
        string calldata name_,
        string calldata bio
    ) public {
        collection.writeString(StorageLocation.ENGINE, tokenId, "name", name_);
        collection.writeString(StorageLocation.ENGINE, tokenId, "bio", bio);
    }

    function _computeName(ICollection nft, uint256)
        internal
        view
        override
        returns (string memory)
    {
        string memory name_ = nft.readString(StorageLocation.ENGINE, "name");
        return string(abi.encodePacked("R Group: ", name_));
    }

    function _computeDescription(ICollection nft, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        string memory name_ = nft.readString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        string memory bio = nft.readString(
            StorageLocation.ENGINE,
            tokenId,
            "bio"
        );
        uint256 mintedTo = nft.readInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "mintedTo"
        );
        uint256 mintedBy = nft.readInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "mintedBy"
        );
        uint256 timestamp = nft.readInt(
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
                    HexStrings.toHexString(mintedTo, 20),
                    " \\n\\nOriginally minted by ",
                    HexStrings.toHexString(mintedBy, 20),
                    " at timestamp ",
                    timestamp.toString(),
                    ".\\n\\n Token ID #",
                    tokenId.toString(),
                    ".\\n\\n Powered by https://heyshell.xyz"
                )
            );
    }

    function _computeImageUri(ICollection, uint256)
        internal
        pure
        override
        returns (string memory)
    {
        return
            "https://ipfs.hypervibes.xyz/ipfs/QmXuSWsCCEmNcuugzoNrFBYYCtQoJjKM4qyoeyvbVa8z4Z";
    }

    function _computeExternalUrl(ICollection, uint256)
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
}
