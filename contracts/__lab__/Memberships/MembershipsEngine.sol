// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Base64} from "../../libraries/Base64.sol";
import {IEngine, ShellBaseEngine} from "../../engines/ShellBaseEngine.sol";
import {IShellERC721, MembershipsLogic, IShellFramework} from "./MembershipsLogic.sol";
import {ImageDescriptor} from "./ImageDescriptor.sol";
import {IERC165} from "../../IShellFramework.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IReverseRecords {
    function getNames(address[] calldata)
        external
        view
        returns (string[] memory r);
}

contract MembershipsEngine is
    MembershipsLogic,
    ImageDescriptor,
    ShellBaseEngine
{
    using Strings for uint256;

    // ---
    // State
    // ---

    IReverseRecords public reverseRecords;

    // ---
    // Constructor
    // ---

    constructor(address reverseRecords_) {
        address[] memory addresses = new address[](1);
        addresses[0] = address(this);
        reverseRecords = IReverseRecords(reverseRecords_);
        // check that reverseRecords has this function
        require(
            reverseRecords.getNames(addresses).length == 1,
            "Invalid reverseRecords"
        );
    }

    // ---
    // External functions
    // ---

    // Get the name for this engine
    function name() external pure returns (string memory) {
        return "memberships-engine-0.0.1";
    }

    // Disable new forks using this engine, as they will not work properly
    function afterEngineSet(uint256 forkId) external pure override {
        require(forkId == 0, "No new forks");
    }

    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory name_ = _computeName(collection, tokenId);
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
                                name_,
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

    // ---
    // Public functions
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IEngine).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // ---
    // Private functions
    // ---

    // compute the metadata name for a given token
    function _computeName(IShellFramework collection, uint256 tokenId)
        private
        view
        returns (string memory)
    {
        address owner = IShellERC721(address(collection)).ownerOf(tokenId);
        require(owner != address(0), "Nonexistent token");
        address[] memory addresses = new address[](1);
        addresses[0] = owner;
        return reverseRecords.getNames(addresses)[0];
    }

    // compute the metadata description for a given token
    function _computeDescription(IShellFramework collection, uint256 tokenId)
        private
        view
        returns (string memory)
    {
        string memory member = _computeName(collection, tokenId);
        address owner = IShellERC721(address(collection)).ownerOf(tokenId);
        if (bytes(member).length == 0)
            member = uint256(uint160(owner)).toHexString(20);
        string memory tokenName = collection.name();
        (, uint256 mintedAt) = latestTokenOf(collection, owner);
        uint256 expiresAt = mintedAt + expiryOf(collection);

        return
            string(
                abi.encodePacked(
                    "Membership NFT: ",
                    tokenName,
                    " \\n\\nOnly valid if held by ",
                    member,
                    " \\n\\nExpires at timestamp ",
                    expiresAt.toString(),
                    ".\\n\\n Token ID #",
                    tokenId.toString(),
                    ".\\n\\n Powered by https://heyshell.xyz"
                )
            );
    }

    // compute the metadata image field for a given token
    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        private
        view
        returns (string memory)
    {
        return
            _tokenImageURI(
                _computeName(collection, tokenId),
                IShellERC721(address(collection)).name(),
                tokenId.toString()
            );
    }

    // compute the external_url field for a given token
    function _computeExternalUrl(IShellFramework collection, uint256)
        private
        view
        returns (string memory)
    {
        return externalUrlOf(collection);
    }
}
