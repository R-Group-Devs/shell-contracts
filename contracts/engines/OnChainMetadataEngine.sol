//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Base64.sol";
import "../IEngine.sol";

abstract contract OnChainMetadataEngine is IEngine {
    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(ICollection collection, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory name = _computeName(collection, tokenId);
        string memory description = _computeDescription(collection, tokenId);
        string memory image = _computeImageUri(collection, tokenId);
        string memory externalUrl = _computeExternalUrl(collection, tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                image,
                                '", "external_url": "',
                                externalUrl,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    // compute the metadata name for a given token
    function _computeName(ICollection nft, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata description for a given token
    function _computeDescription(ICollection nft, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata image field for a given token
    function _computeImageUri(ICollection nft, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the external_url field for a given token
    function _computeExternalUrl(ICollection nft, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);
}
