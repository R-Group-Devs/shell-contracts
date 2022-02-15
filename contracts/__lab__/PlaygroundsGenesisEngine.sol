// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../engines/ShellBaseEngine.sol";
import "../engines/OnChainMetadataEngine.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PlaygroundsGenesisEngine is ShellBaseEngine, OnChainMetadataEngine {
    function name() external pure returns (string memory) {
        return "playgrounds-genesis-v0.4";
    }

    function mint(IShellFramework collection, uint256 flag)
        external
        returns (uint256)
    {
        IntStorage[] memory intData;

        // flag is written to token mint data if set
        if (flag != 0) {
            intData = new IntStorage[](1);
            intData[0] = IntStorage({key: "flag", value: flag});
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

    function getVariation(uint256 tokenId, uint256 flag)
        public
        pure
        returns (string memory)
    {
        if (flag == 2) {
            // celestial
            return "X001";
        } else if (flag == 1) {
            // mythical
            uint256 i = uint256(keccak256(abi.encodePacked(tokenId))) % 4;
            return string(abi.encodePacked("M00", Strings.toString(i + 1)));
        }

        // citizen
        uint256 index = uint256(keccak256(abi.encodePacked(tokenId))) % 10;

        if (index == 9) {
            return "C010"; // double digit case
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

    function getFlag(IShellFramework collection, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return
            collection.readTokenInt(StorageLocation.MINT_DATA, tokenId, "flag");
    }

    function _computeName(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        uint256 flag = getFlag(collection, tokenId);

        return
            string(
                abi.encodePacked(
                    "Morph #",
                    Strings.toString(tokenId),
                    flag == 2 ? ": Cosmic Scroll of " : flag == 1
                        ? ": Mythical Scroll of "
                        : ": Scroll of ",
                    getPaletteName(tokenId)
                )
            );
    }

    function _computeDescription(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        uint256 flag = getFlag(collection, tokenId);

        return
            string(
                abi.encodePacked(
                    flag == 2
                        ? "A mysterious scroll... you feel it pulsating with cosmic energy. Its whispers speak secrets of cosmic significance."
                        : flag == 1
                        ? "A mysterious scroll... you feel it pulsating with mythical energy. You sense its power is great."
                        : "A mysterious scroll... you feel it pulsating with energy. What secrets might it hold?",
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
        uint256 flag = getFlag(collection, tokenId);

        string memory image = string(
            abi.encodePacked(
                "S001-",
                getPalette(tokenId),
                "-",
                getVariation(tokenId, flag),
                ".png"
            )
        );

        return
            string(
                abi.encodePacked(
                    "ipfs://ipfs/QmRCKXGuM47BzepjiHu2onshPFRWb7TMVEfd4K87cszg4w/",
                    image
                )
            );
    }

    // compute the external_url field for a given token
    function _computeExternalUrl(IShellFramework, uint256)
        internal
        pure
        override
        returns (string memory)
    {
        return "https://playgrounds.wtf";
    }
}
