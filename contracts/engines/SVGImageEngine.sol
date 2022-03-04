//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Base64.sol";
import "./OnChainMetadataEngine.sol";

/// @notice Extends on chain metadata base engine to use an SVG document in the
/// image metadata field
abstract contract SVGImageEngine is OnChainMetadataEngine {
    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        return
            string.concat(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(_computeSVGDocument(collection, tokenId)))
            );
    }

    /// @notice should return a complete <svg> document
    function _computeSVGDocument(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);
}
