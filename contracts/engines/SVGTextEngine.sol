//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./SVGImageEngine.sol";
import "./ShellBaseEngine.sol";

struct TextConfig {
    string bgColor;
    string fgColor;
    string fontFamily;
    uint32 fontSize;
    uint32 height;
    uint32 width;
    uint32 padding;
    uint32 lineHeight;
}

/// @notice Basic text SVG NFT image
abstract contract SVGTextEngine is SVGImageEngine {
    using Strings for uint256;

    /// @notice should return a complete <svg> document
    function _computeSVGDocument(IShellFramework collection, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        TextConfig memory config = _computeTextConfig(collection, tokenId);
        string[] memory lines = _computeText(collection, tokenId);

        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" ',
            'viewBox="0 0 ',
            uint256(config.width).toString(),
            " ",
            uint256(config.height).toString(),
            '">',
            "<style>.base { fill: ",
            config.fgColor,
            "; font-family: ",
            config.fontFamily,
            "; font-size: ",
            uint256(config.fontSize).toString(),
            "px; }</style>",
            '<rect width="100%" height="100%" fill="',
            config.bgColor,
            '" />'
        );

        for (uint256 i = 0; i < lines.length; i++) {
            svg = string.concat(
                svg,
                '<text x="',
                uint256(config.padding).toString(),
                '" y="',
                uint256(config.lineHeight + config.lineHeight * i).toString(),
                '" class="base">',
                lines[i],
                "</text>"
            );
        }

        svg = string.concat(svg, "</svg>");

        return svg;
    }

    /// @notice get the text configuration for a token. Override to change appearance
    function _computeTextConfig(IShellFramework, uint256)
        internal
        view
        virtual
        returns (TextConfig memory)
    {
        return
            TextConfig({
                bgColor: "#222",
                fgColor: "#FDFFFC",
                fontFamily: '"DM Mono", monospace',
                fontSize: 12,
                height: 350,
                width: 350,
                padding: 10,
                lineHeight: 20
            });
    }

    /// @notice return an array of text lines to display. Should be overriden
    function _computeText(IShellFramework collection, uint256 tokenId)
        internal
        view
        virtual
        returns (string[] memory);
}
