// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../engines/ShellBaseEngine.sol";
import "../engines/OnChainMetadataEngine.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PlaygroundsGenesisEngine is ShellBaseEngine, OnChainMetadataEngine {
    function name() external pure returns (string memory) {
        return "playgrounds-genesis-v0.1";
    }

    function mint(IShellFramework collection, bool flag)
        external
        returns (uint256)
    {
        IntStorage[] memory intData;

        // flag is written to token mint data if set
        if (flag) {
            intData = new IntStorage[](1);
            intData[0] = IntStorage({key: "isFlagged", value: flag ? 1 : 0});
        } else {
            intData = new IntStorage[](0);
        }

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
                    intData: intData
                })
            })
        );

        return tokenId;
    }

    function getPalette(uint256 tokenId) public pure returns (string memory) {
        uint256 index = uint256(keccak256(abi.encodePacked(tokenId))) % 6;
        return string(abi.encodePacked("P00", Strings.toString(index + 1)));
    }

    function getVariation(uint256 tokenId, bool isFlagged)
        public
        pure
        returns (string memory)
    {
        // if flagged, pic one of the 5 rare variations
        if (isFlagged) {
            uint256 i = uint256(keccak256(abi.encodePacked(tokenId))) % 5;
            return string(abi.encodePacked("R00", Strings.toString(i + 1)));
        }

        uint256 index = uint256(keccak256(abi.encodePacked(tokenId))) % 15;
        if (index == 9) {
            return "C010"; // double digit case
        } else if (index > 9) {
            return string(abi.encodePacked("R00", Strings.toString(index - 9)));
        } else {
            return string(abi.encodePacked("C00", Strings.toString(index + 1)));
        }
    }

    function getPaletteName(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        uint256 index = uint256(keccak256(abi.encodePacked(tokenId))) % 6;

        if (index == 0) {
            return "Greyskull";
        } else if (index == 1) {
            return "Ancient Opinions";
        } else if (index == 2) {
            return "The Desert Sun";
        } else if (index == 3) {
            return "The Deep";
        } else if (index == 4) {
            return "The Jade Prism";
        } else if (index == 5) {
            return "Cosmic Understanding";
        }

        return "";
    }

    function getIsFlagged(IShellFramework collection, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return
            collection.readTokenInt(
                StorageLocation.MINT_DATA,
                tokenId,
                "isFlagged"
            ) == 1;
    }

    function _computeName(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "Morph #",
                    Strings.toString(tokenId),
                    getIsFlagged(collection, tokenId)
                        ? ": Mythical Scroll of "
                        : ": Scroll of ",
                    getPaletteName(tokenId)
                )
            );
    }

    // compute the metadata description for a given token
    function _computeDescription(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "A mysterious scroll... you feel it pulsating with cosmic energy. What secrets might it hold?",
                    getIsFlagged(collection, tokenId)
                        ? "\\n\\nA mythical mark has been permanently etched into this NFT."
                        : "",
                    "\\n\\nhttps://playgrounds.wtf"
                )
            );
    }

    // compute the metadata image field for a given token
    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        bool isFlagged = getIsFlagged(collection, tokenId);

        string memory image = string(
            abi.encodePacked(
                "E001-",
                getPalette(tokenId),
                "-",
                getVariation(tokenId, isFlagged),
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
