//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEngine} from "../../IEngine.sol";
import {ICollection, StringStorage, IntStorage, MintOptions, StorageLocation} from "../../ICollection.sol";
import {Collection} from "../../Collection.sol";
import {IPersonalizedDescriptor} from "./IPersonalizedDescriptor.sol";
import {NoRoyaltiesEngine} from "../../engines/NoRoyaltiesEngine.sol";

/**
 * Insert standard reference to shell here
 */

// TODO ICollection should probably have "is IOwnable, IERC721" if possible (also nextTokenId(), please!)
// b/c it isn't now, I have to import Collection and do Collection(address(collection)).ownableMethod()

// TODO events

// TODO "fan" NFTs can be implemented as an independent lego, since they grant no priviliges and should be a separate collection

contract SquadzEngine is IEngine, NoRoyaltiesEngine {

    //===== Engine State =====//

    IPersonalizedDescriptor immutable defaultDescriptor;

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

    // display name for this engine
    function name() external pure returns (string memory) {
        return "SQUADZ v0.0.0";
    }

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(ICollection collection, uint256 tokenId)
        external
        view
        returns (string memory) {
        IPersonalizedDescriptor descriptor;
        if (isAdmin(collection, tokenId)) {
            descriptor = _getDescriptor(collection, true);
        } else {
            descriptor = _getDescriptor(collection, false);
        }
        if (address(descriptor) == address(0)) descriptor = defaultDescriptor;
        return descriptor.getTokenURI(
            address(collection), 
            tokenId, 
            Collection(address(collection)).ownerOf(tokenId)
        );
    }

    // Called by the collection during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    function beforeTokenTransfer(
        ICollection collection,
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(msg.sender == address(collection), "SQUADZ: beforeTokenTransfer caller not collection");
        // if token is admin, increment and decrement adminTokenCount appropriately
        if (isAdmin(collection, tokenId)) {
            _decrementAdminTokenCount(collection, from);
            _incrementAdminTokenCount(collection, to);
        }
    }

    function setDescriptor(ICollection collection, address descriptorAddress, bool admin) external {
        require(
            Collection(address(collection)).owner() == msg.sender, 
            "SQUADZ: sender not collection owner"
        );
        _setDescriptorAddress(collection, descriptorAddress, admin);
    }

    //===== Public Functions =====//

    function mint(
        ICollection collection,
        address to,
        bool admin
    ) public returns (uint256) {
        require(
            isAdmin(collection, msg.sender) || Collection(address(collection)).owner() == msg.sender,
            "SQUADZ: only collection owner or admin token holder can mint"
        );

        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](1);
        if (admin == true) {
          intData[0].key = _adminTokenKey(
              Collection(address(collection)).nextTokenId() + 1
          );
          intData[0].value = 1;
          _incrementAdminTokenCount(collection, to);
        }

        uint256 tokenId = collection.mint(
            to,
            // minimal storage for minimal gas cost
            MintOptions({
                storeEngine: false,
                storeMintedTo: true,
                storeMintedBy: false,
                storeTimestamp: false,
                storeBlockNumber: false,
                stringData: stringData,
                intData: intData
            })
        );

        return tokenId;
    }

    function batchMint(
        ICollection collection,
        address[] calldata toAddresses,
        bool[] calldata adminBools
    ) public returns (uint256[] memory) {
        require(toAddresses.length == adminBools.length, "SQUADZ: toAddresses and adminBools arrays have different lengths");
        uint256[] memory ids = new uint256[](adminBools.length);
        for (uint256 i = 0; i < adminBools.length; i++) {
            ids[i] = mint(collection, toAddresses[i], adminBools[i]);
        }
        return ids;
    }

    // TODO burn -- need this to be implemented in Collection first

    function isAdmin(ICollection collection, uint256 tokenId) public view returns (bool) {
        require(
            Collection(address(collection)).ownerOf(tokenId) != address(0), 
            "SQUADZ: token doesn't exist"
        );
        return collection.readInt(StorageLocation.MINT_DATA, _adminTokenKey(tokenId)) == 1;
    }

    function isAdmin(ICollection collection, address address_) public view returns (bool) {
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
        return interfaceId == type(IEngine).interfaceId;
    }

    //===== Internal Functions =====//

    function _setDescriptorAddress(ICollection collection, address descriptorAddress, bool admin) internal {
        IPersonalizedDescriptor descriptor = IPersonalizedDescriptor(descriptorAddress);
        require(
            descriptor.supportsInterface(type(IPersonalizedDescriptor).interfaceId),
            "SQUADZ: invalid descriptor address"
        );
        if (admin == true) {
            collection.writeInt(
                StorageLocation.ENGINE, 
                _adminDescriptorKey(), 
                uint256(uint160(descriptorAddress))
            );
        } else {
            collection.writeInt(
                StorageLocation.ENGINE, 
                _memberDescriptorKey(), 
                uint256(uint160(descriptorAddress))
            );
        }
    }

    function _getDescriptor(ICollection collection, bool admin) internal view returns (IPersonalizedDescriptor) {
        IPersonalizedDescriptor descriptor;
        if (admin == true) {
            descriptor = IPersonalizedDescriptor(address(uint160(
                collection.readInt(
                    StorageLocation.ENGINE, 
                    _adminDescriptorKey()
                )
            )));
        } else {
            descriptor = IPersonalizedDescriptor(address(uint160(
                collection.readInt(
                    StorageLocation.ENGINE, 
                    _memberDescriptorKey()
                )
            )));
        }
        return descriptor;
    }

    //===== Private Functions =====//

    function _adminTokenKey(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(tokenId, "ADMIN_TOKEN"));
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

    function _adminTokenCount(ICollection collection, address address_) private view returns (uint256) {
        return collection.readInt(StorageLocation.ENGINE, _adminTokenCountKey(address_));
    }

    function _setAdminTokenCount(ICollection collection, address address_, uint256 value) private {
        collection.writeInt(StorageLocation.ENGINE, _adminTokenCountKey(address_), value);
    }

    function _incrementAdminTokenCount(ICollection collection, address address_) private {
        uint256 count = _adminTokenCount(collection, address_);
        _setAdminTokenCount(collection, address_, count + 1);
    }

    function _decrementAdminTokenCount(ICollection collection, address address_) private {
        uint256 count = _adminTokenCount(collection, address_);
        require(count > 0, "SQUADZ: cannot decrement admin token count of 0");
        _setAdminTokenCount(collection, address_, count - 1);
    }
}