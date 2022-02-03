// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../engines/ShellBaseEngine.sol";
import "../engines/OnChainMetadataEngine.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PlaygroundsGenesisEngine is ShellBaseEngine, OnChainMetadataEngine {
    function name() external pure returns (string memory) {
        return "playgrounds-genesis-v0";
    }

    function mint(IShellFramework collection, string calldata code)
        external
        returns (uint256)
    {
        uint256 tokenId = collection.mint(
            MintEntry({
                to: msg.sender,
                amount: 1,
                options: MintOptions({
                    storeEngine: false,
                    storeMintedTo: false,
                    storeTimestamp: false,
                    storeBlockNumber: false,
                    stringData: new StringStorage[](0),
                    intData: new IntStorage[](0)
                })
            })
        );

        return tokenId;
    }

    function getPalette(uint256 tokenId) public pure returns (string memory) {
        uint256 index = uint256(keccak256(abi.encodePacked(tokenId))) % 6;
        return string(abi.encodePacked("P00", Strings.toString(index + 1)));
    }

    function getVariation(uint256 tokenId) public pure returns (string memory) {
        uint256 index = uint256(keccak256(abi.encodePacked(tokenId))) % 15;

        if (index == 9) {
            return "C010";
        } else if (index > 9) {
            return string(abi.encodePacked("R00", Strings.toString(index - 9)));
        } else {
            return string(abi.encodePacked("C00", Strings.toString(index + 1)));
        }
    }

    function _computeName(IShellFramework, uint256 tokenId)
        internal
        pure
        override
        returns (string memory)
    {
        return string(abi.encodePacked("Morph #", Strings.toString(tokenId)));
    }

    // compute the metadata description for a given token
    function _computeDescription(IShellFramework, uint256 tokenId)
        internal
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "A mysterious scroll... you feel it pulsating with cosmic energy. What secrets might it hold?",
                    "\\n\\nhttps://playgrounds.wtf"
                )
            );
    }

    // compute the metadata image field for a given token
    function _computeImageUri(IShellFramework, uint256 tokenId)
        internal
        pure
        override
        returns (string memory)
    {
        string memory image = string(
            abi.encodePacked(
                "E001-",
                getPalette(tokenId),
                "-",
                getVariation(tokenId),
                ".png"
            )
        );
        return
            string(
                abi.encodePacked(
                    "ipfs://ipfs/QmNr1uDyFvN3SBBw4NFBC9V7WZLrFzne2Q1xqnUbaS5WcJ/",
                    image
                )
            );
    }

    // compute the external_url field for a given token
    function _computeExternalUrl(IShellFramework, uint256 tokenId)
        internal
        pure
        override
        returns (string memory)
    {
        return "https://playgrounds.wtf";
    }
}
