//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "../../libraries/Base64.sol";
import {IPersonalizedDescriptor} from "./IPersonalizedDescriptor.sol";
import {IReverseRecords} from "../SNS/IReverseRecords.sol";

contract SimpleDescriptor is IPersonalizedDescriptor {

    //===== State =====//

    IReverseRecords public reverseRecords;

    struct RgbColor {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    //===== Constructor =====//

    constructor(address reverseRecordsAddr) {
        reverseRecords = IReverseRecords(reverseRecordsAddr);
        // Not using supportsInterface here because ENS does not use interfaces, 
        // and I want to be able to use ENS here
        address[] memory a = new address[](1);
        a[0] = address(this);
        require(
            reverseRecords.getNames(a).length == 1, 
            "Contract at reverseRecordsAddr must support `getNames`"
        );
    }

    //===== External Functions =====//

    function getTokenURI(address collectionAddr, uint256 tokenId, address owner) external view returns (string memory) {
        address[] memory a = new address[](1);
        a[0] = owner;
        string memory name = reverseRecords.getNames(a)[0];
        ERC721 collection = ERC721(collectionAddr);
        string memory output = _buildOutput(
            collection,
            tokenId,
            name
        );
        // prettier-ignore
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
          '{ "id": ',
          Strings.toString(tokenId),
          ', "ownerName": "',
          name,
          '", "tokenName": "',
          collection.name(),
          '", "image": "data:image/svg+xml;base64,',
          Base64.encode(bytes(output)),
          '" }'
        ))));
        // prettier-ignore
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    //===== Public Functions =====//

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IPersonalizedDescriptor).interfaceId;
    }

    //===== Private Functions =====//

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
                    Strings.toString(rgb.r),
                    ",",
                    Strings.toString(rgb.g),
                    ",",
                    Strings.toString(rgb.b),
                    ", 1)"
                )
            );
    }

    function _buildOutput(ERC721 collection, uint256 tokenId, string memory name)
        private
        view
        returns (string memory)
    {
        RgbColor memory rgb1 = _pluckColor(
            collection.name(),
            collection.symbol()
        );
        RgbColor memory rgb2 = _rotateColor(rgb1);
        string memory color1 = _colorToString(rgb1);
        // prettier-ignore
        string memory output = string(abi.encodePacked(
          '<svg width="300" height="400" viewBox="0 0 300 400" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="300" height="400" rx="140" fill="url(#paint0_radial_1_3)"/><style>.main { font: 24px sans-serif; fill:',
          color1,
          '; }</style><text x="50%" y="176px" text-anchor="middle" class="main">',
          name,
          '</text><text x="50%" y="206px" text-anchor="middle" class="main">',
          collection.name(),
          '</text><text x="50%" y="236px" text-anchor="middle" class="main">',
          Strings.toString(tokenId)
        ));
        // prettier-ignore
        return string(abi.encodePacked(
          output,
          '</text><defs><radialGradient id="paint0_radial_1_3" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(150 200) rotate(90) scale(207 170)"><stop stop-color="',
          _colorToString(rgb2),
          '"/><stop offset="1" stop-color="',
          color1,
          '"/></radialGradient></defs></svg>'
        ));
    }
}