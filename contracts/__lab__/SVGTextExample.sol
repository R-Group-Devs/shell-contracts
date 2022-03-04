//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Base64.sol";
import "../engines/ShellBaseEngine.sol";
import "../engines/SVGTextEngine.sol";

contract SVGTextExample is ShellBaseEngine, SVGTextEngine {
    using Strings for uint256;

    function name() external pure returns (string memory) {
        return "svg-text-example";
    }

    function mint(
        IShellFramework collection,
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
        return string(abi.encodePacked("Member: ", name_));
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
                    "Example membership NFT. \\n\\nMember: ",
                    name_,
                    " \\n\\n",
                    bio,
                    " \\n\\nOriginally minted to ",
                    mintedTo.toHexString(20),
                    " \\n\\nMinted at timestamp ",
                    timestamp.toString(),
                    ".\\n\\n Token ID #",
                    tokenId.toString(),
                    ".\\n\\n Powered by https://heyshell.xyz"
                )
            );
    }

    function _computeText(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string[] memory)
    {
        string[] memory lines = new string[](4);

        string memory name_ = collection.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        uint256 timestamp = collection.readTokenInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "timestamp"
        );

        lines[0] = string(abi.encodePacked("Token #", tokenId.toString()));
        lines[1] = string(abi.encodePacked("Member: ", name_));
        lines[2] = string(abi.encodePacked("Joined: ", timestamp.toString()));
        lines[3] = "powered by heyshell.xyz";

        return lines;
    }

    function _computeExternalUrl(IShellFramework, uint256)
        internal
        pure
        override
        returns (string memory)
    {
        return "https://playgrounds.wtf";
    }

    function _computeAttributes(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (Attribute[] memory)
    {
        Attribute[] memory attributes = new Attribute[](2);
        string memory name_ = collection.readTokenString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        uint256 timestamp = collection.readTokenInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "timestamp"
        );
        attributes[0] = Attribute({key: "Name", value: name_});
        attributes[1] = Attribute({key: "Joined", value: timestamp.toString()});
        return attributes;
    }
}
