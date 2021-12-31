//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEngine} from "../../IEngine.sol";
import {ISquadzEngine} from "./ISquadzEngine.sol";
import {IShellFramework, MintEntry} from "../../IShellFramework.sol";
import {IShellERC721, StringStorage, IntStorage, MintOptions, StorageLocation} from "../../IShellERC721.sol";
import {IPersonalizedDescriptor} from "./IPersonalizedDescriptor.sol";
import {NoRoyaltiesEngine} from "../../engines/NoRoyaltiesEngine.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * Insert standard reference to shell here
 */

// NOTE If an engine is built without a need for many of its own events, this makes it much easier to spin up UIs, since the app 
// can depend on the existing shell subgraph.

// NOTE "fan" NFTs can be implemented as an independent lego, since they grant no priviliges and should be a separate collection

contract SquadzEngine is ISquadzEngine, NoRoyaltiesEngine {

    //===== Engine State =====//

    IPersonalizedDescriptor public immutable defaultDescriptor;

    //===== Constructor =====//

    constructor(address descriptorAddress) {
        IPersonalizedDescriptor descriptor = IPersonalizedDescriptor(descriptorAddress);
        require(
            descriptor.supportsInterface(type(IPersonalizedDescriptor).interfaceId),
            "SQUADZ: invalid descriptor address"
        );
        defaultDescriptor = descriptor;
    }

    //===== External Functions =====//

    // Called by the framework following an engine install. Can be used by the
    // engine to block (by reverting) installation if needed.
    // The engine MUST assert msg.sender == collection address!!
    // TODO Check IERC721Upgradeable as well, because this does not check inherited functions
    function afterInstallEngine(IShellFramework collection) external view {
        require(
            collection.supportsInterface(type(IShellERC721).interfaceId) &&
            collection.supportsInterface(type(IERC721Upgradeable).interfaceId),
            "SQUADZ: collection must support IShellERC721"
        );
    }

    function afterInstallEngine(IShellFramework, uint256) external pure {
        revert("SQUADZ: cannot install engine to individual tokens");
    }

    // Get the name for this engine
    function getEngineName() external pure returns (string memory) {
        return "SQUADZ v0.0.0";
    }

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory) {
        IPersonalizedDescriptor descriptor;
        IShellERC721 token = IShellERC721(address(collection));
        if (isAdminToken(token, tokenId)) {
            descriptor = getDescriptor(collection, true);
        } else {
            descriptor = getDescriptor(collection, false);
        }
        if (address(descriptor) == address(0)) descriptor = defaultDescriptor;
        return descriptor.getTokenURI(
            address(collection),
            tokenId,
            token.ownerOf(tokenId)
        );
    }

    // Called by the collection during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    function beforeTokenTransfer(
        IShellFramework collection,
        address,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external {
        require(msg.sender == address(collection), "SQUADZ: beforeTokenTransfer caller not collection");
        // if token is admin, increment and decrement adminTokenCount appropriately
        if (tokenIds.length == 0) return;
        require(tokenIds.length == amounts.length, "SQUADZ: array length mismatch");
        // TODO if multiple tokens can be transferred at the same time, do a loop here
        if (isAdminToken(IShellERC721(address(collection)), tokenIds[0])) {
            _decrementAdminTokenCount(collection, from);
            _incrementAdminTokenCount(collection, to);
        }
    }

    function setDescriptor(IShellERC721 collection, address descriptorAddress, bool admin) external {
        require(
            collection.owner() == msg.sender,
            "SQUADZ: sender not collection owner"
        );
        IPersonalizedDescriptor descriptor = IPersonalizedDescriptor(descriptorAddress);
        require(
            descriptor.supportsInterface(type(IPersonalizedDescriptor).interfaceId),
            "SQUADZ: invalid descriptor address"
        );
        if (admin == true) {
            collection.writeCollectionInt(
                StorageLocation.ENGINE,
                _adminDescriptorKey(),
                uint256(uint160(descriptorAddress))
            );
        } else {
            collection.writeCollectionInt(
                StorageLocation.ENGINE,
                _memberDescriptorKey(),
                uint256(uint160(descriptorAddress))
            );
        }
    }

    function mint(
        IShellERC721 collection,
        address to,
        bool admin
    ) external returns (uint256) {
        require(
            isAdmin(collection, msg.sender) || collection.owner() == msg.sender,
            "SQUADZ: only collection owner or admin token holder can mint"
        );
        return _mint(collection, to, admin);
    }

    // NOTE I think the interface batchMint that uses an array of MintEntries might not be neccessary, and is kind of annoying to implement 
    // I would have to create an array of mint entries here rather than getting to reuse my mint function, right?
    function batchMint(
        IShellERC721 collection,
        address[] calldata toAddresses,
        bool[] calldata adminBools
    ) external returns (uint256[] memory) {
        require(toAddresses.length == adminBools.length, "SQUADZ: toAddresses and adminBools arrays have different lengths");
        require(
            isAdmin(collection, msg.sender) || collection.owner() == msg.sender,
            "SQUADZ: only collection owner or admin token holder can mint"
        );
        uint256[] memory ids = new uint256[](adminBools.length);
        for (uint256 i = 0; i < adminBools.length; i++) {
            ids[i] = _mint(collection, toAddresses[i], adminBools[i]);
        }
        return ids;
    }

    function mintedTo(IShellFramework collection, uint256 tokenId) external view returns (address) {
        return address(uint160(
          collection.readTokenInt(
              StorageLocation.FRAMEWORK,
              tokenId,
              "mintedTo"
          )
        ));
    }

    // TODO burn -- need this to be implemented in ShellERC721 first, I think

    //===== Public Functions =====//

    // does not show a token exists (will return false for non-existant tokens)
    function isAdminToken(IShellERC721 collection, uint256 tokenId) public view returns (bool) {
        return collection.readTokenInt(StorageLocation.MINT_DATA, tokenId, _adminTokenKey()) == 1;
    }

    function isAdmin(IShellFramework collection, address address_) public view returns (bool) {
        if (_adminTokenCount(collection, address_) > 0) return true;
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IEngine).interfaceId ||
            interfaceId == type(ISquadzEngine).interfaceId;
    }

    function getDescriptor(IShellFramework collection, bool admin) public view returns (IPersonalizedDescriptor) {
        IPersonalizedDescriptor descriptor;
        if (admin == true) {
            descriptor = IPersonalizedDescriptor(address(uint160(
                collection.readCollectionInt(
                    StorageLocation.ENGINE,
                    _adminDescriptorKey()
                )
            )));
        } else {
            descriptor = IPersonalizedDescriptor(address(uint160(
                collection.readCollectionInt(
                    StorageLocation.ENGINE,
                    _memberDescriptorKey()
                )
            )));
        }
        return descriptor;
    }

    //===== Internal Functions =====//

    function _mint(
        IShellERC721 collection,
        address to,
        bool admin
    ) internal returns (uint256) {

        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](1);
        if (admin == true) {
          intData[0].key = _adminTokenKey();
          intData[0].value = 1;
          // does beforeTokenTransfer cover this? 
          // Nope, it doesn't, because the token won't be an admin token before it's been minted, 
          // and beforeTokenTransfer gets called before the mint (i.e. transfer)
          _incrementAdminTokenCount(collection, to);
        }

        uint256 tokenId = collection.mint(MintEntry({
            to: to,
            amount: 1,
            options:
                // minimal storage for minimal gas cost
                MintOptions({
                    storeEngine: false,
                    storeMintedTo: true,
                    storeTimestamp: false,
                    storeBlockNumber: false,
                    stringData: stringData,
                    intData: intData
                })
            })
        );

        return tokenId;
    }

    //===== Private Functions =====//

    function _adminTokenKey() private pure returns (string memory) {
        return "ADMIN_TOKEN";
    }

    function _adminTokenCountKey(address address_) private pure returns (string memory) {
        return string(abi.encodePacked(address_, "ADMIN_TOKEN_COUNT"));
    }

    function _adminDescriptorKey() private pure returns (string memory) {
        return "ADMIN_DESCRIPTOR_KEY";
    }

    function _memberDescriptorKey() private pure returns (string memory) {
        return "MEMBER_DESCRIPTOR_KEY";
    }

    function _adminTokenCount(IShellFramework collection, address address_) private view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, _adminTokenCountKey(address_));
    }

    function _setAdminTokenCount(IShellFramework collection, address address_, uint256 value) private {
        collection.writeCollectionInt(StorageLocation.ENGINE, _adminTokenCountKey(address_), value);
    }

    function _incrementAdminTokenCount(IShellFramework collection, address address_) private {
        uint256 count = _adminTokenCount(collection, address_);
        _setAdminTokenCount(collection, address_, count + 1);
    }

    function _decrementAdminTokenCount(IShellFramework collection, address address_) private {
        uint256 count = _adminTokenCount(collection, address_);
        require(count > 0, "SQUADZ: cannot decrement admin token count of 0");
        _setAdminTokenCount(collection, address_, count - 1);
    }
}
