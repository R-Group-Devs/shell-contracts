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

    function _computeName(IShellFramework, uint256 tokenId)
        internal
        pure
        override
        returns (string memory)
    {
        return string(abi.encodePacked("Scroll #", Strings.toString(tokenId)));
    }

    // compute the metadata description for a given token
    function _computeDescription(IShellFramework, uint256 tokenId)
        internal
        pure
        override
        returns (string memory)
    {
        return string(abi.encodePacked("Scroll #", Strings.toString(tokenId)));
    }

    // compute the metadata image field for a given token
    function _computeImageUri(IShellFramework, uint256 tokenId)
        internal
        pure
        override
        returns (string memory)
    {
        return
            "ipfs://ipfs/QmNr1uDyFvN3SBBw4NFBC9V7WZLrFzne2Q1xqnUbaS5WcJ/E001-P001-C001.png";
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
