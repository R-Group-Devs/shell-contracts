//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "../../libraries/Base64.sol";

contract ImageDescriptor {
    using Strings for uint256;

    // ---
    // Structs
    // ---

    struct RgbColor {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    // ---
    // Internal functions
    // ---

    function _tokenImageURI(
        string memory memberName,
        string memory tokenName,
        string memory tokenId
    ) internal pure returns (string memory) {
        string memory output = _buildOutput(memberName, tokenName, tokenId);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(output))
                )
            );
    }

    // ---
    // Private functions
    // ---

    function _random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _pluckColor(string memory seed1, string memory seed2)
        private
        pure
        returns (RgbColor memory)
    {
        RgbColor memory rgb = RgbColor(
            _random(string(abi.encodePacked(seed1, seed2))) % 255,
            _random(seed1) % 255,
            _random(seed2) % 255
        );
        return rgb;
    }

    function _rotateColor(RgbColor memory rgb)
        private
        pure
        returns (RgbColor memory)
    {
        RgbColor memory rotated = RgbColor(
            (rgb.r + 128) % 255,
            (rgb.g + 128) % 255,
            (rgb.b + 128) % 255
        );
        return rotated;
    }

    function _colorToString(RgbColor memory rgb)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "rgba",
                    "(",
                    rgb.r.toString(),
                    ",",
                    rgb.g.toString(),
                    ",",
                    rgb.b.toString(),
                    ", 1)"
                )
            );
    }

    function _buildOutput(
        string memory memberName,
        string memory tokenName,
        string memory tokenId
    ) private pure returns (string memory) {
        RgbColor memory rgb1 = _pluckColor(memberName, tokenName);
        RgbColor memory rgb2 = _rotateColor(rgb1);
        string memory color1 = _colorToString(rgb1);
        string memory output = string(
            abi.encodePacked(
                '<svg width="300" height="400" viewBox="0 0 300 400" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="300" height="400" rx="140" fill="url(#paint0_radial_1_3)"/><style>.main { font: 24px sans-serif; fill:',
                color1,
                '; }</style><text x="50%" y="176px" text-anchor="middle" class="main">',
                memberName,
                '</text><text x="50%" y="206px" text-anchor="middle" class="main">',
                tokenName,
                '</text><text x="50%" y="236px" text-anchor="middle" class="main">',
                tokenId
            )
        );
        return
            string(
                abi.encodePacked(
                    output,
                    '</text><defs><radialGradient id="paint0_radial_1_3" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(150 200) rotate(90) scale(207 170)"><stop stop-color="',
                    _colorToString(rgb2),
                    '"/><stop offset="1" stop-color="',
                    color1,
                    '"/></radialGradient></defs></svg>'
                )
            );
    }
}
