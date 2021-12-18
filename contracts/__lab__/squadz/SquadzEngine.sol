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

contract SquadzEngine is IEngine, NoRoyaltiesEngine {

    //===== Engine State =====//

    IPersonalizedDescriptor immutable defaultDescriptor;
    mapping(address => IPersonalizedDescriptor) public adminDescriptors;
    mapping(address => IPersonalizedDescriptor) public memberDescriptors;
    mapping(address => IPersonalizedDescriptor) public fanDescriptors;

    //===== Types =====//

    enum Role {
      NONE, // Because the first enum item will be 0 and the default stored mapping value will be 0
      ADMIN, // can mint all NFT roles, burn admin and member NFTs
      MEMBER // can mint member and fan NFTs
    }

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
        return "SQUADZ";
    }

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(ICollection collection, uint256 tokenId)
        external
        view
        returns (string memory) {
        IPersonalizedDescriptor descriptor;
        Role role = tokenRole(collection, tokenId);
        if (role == Role.ADMIN) {
            descriptor = adminDescriptors[address(collection)];
        } else if (role == Role.MEMBER) {
            descriptor = memberDescriptors[address(collection)];
        } else {
            descriptor = fanDescriptors[address(collection)];
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
        // if token is admin or member, increment and decrement roleCounts appropriately
        Role role = tokenRole(collection, tokenId);
        if (role == Role.ADMIN || role == Role.MEMBER) {
            _decrementAddressRoleCount(collection, from, role);
            _incrementAddressRoleCount(collection, to, role);
        }
    }

    function setDescriptor(ICollection collection, address descriptorAddress, Role role) external {
        require(
            Collection(address(collection)).owner() == msg.sender, 
            "SQUADZ: sender not collection owner"
        );
        IPersonalizedDescriptor descriptor = IPersonalizedDescriptor(descriptorAddress);
        require(
            descriptor.supportsInterface(type(IPersonalizedDescriptor).interfaceId),
            "SQUADZ: invalid descriptor address"
        );
        if (role == Role.ADMIN) {
            adminDescriptors[address(collection)] = descriptor;
        } else if (role == Role.MEMBER) {
            memberDescriptors[address(collection)] = descriptor;
        } else {
            fanDescriptors[address(collection)] = descriptor;
        }
    }

    //===== Public Functions =====//

    function mint(
        ICollection collection,
        address to,
        Role role
    ) public returns (uint256) {
        _validateMint(collection, role);

        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](1);
        intData[0].key = _tokenRoleKey(
            Collection(address(collection)).nextTokenId() + 1
        );
        intData[0].value = uint256(role);

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

        _incrementAddressRoleCount(collection, to, role);

        return tokenId;
    }

    function batchMint(
        ICollection collection,
        address[] calldata toAddresses,
        Role[] calldata roles
    ) public returns (uint256[] memory) {
        require(toAddresses.length == roles.length, "SQUADZ: toAddresses and roles arrays different lengths");
        uint256[] memory ids = new uint256[](roles.length);
        for (uint256 i = 0; i < roles.length; i++) {
            ids[i] = mint(collection, toAddresses[i], roles[i]);
        }
        return ids;
    }

    // TODO burn -- need this to be implemented in Collection first

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IEngine).interfaceId;
    }

    function tokenRole(ICollection collection, uint256 tokenId) public view returns (Role) {
        return Role(collection.readInt(StorageLocation.MINT_DATA, _tokenRoleKey(tokenId)));
    }

    function isRole(ICollection collection, address address_, Role role) public view returns (bool) {
        if (_roleCount(collection, address_, role) > 0) return true;
        return false;
    }

    //===== Private Functions =====//

    function _tokenRoleKey(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encode(tokenId));
    }

    function _addressRoleKey(address address_, Role role) private pure returns (string memory) {
        // TODO this is a very awkward structure! is there a better way?
        return string(abi.encode(keccak256(abi.encodePacked(address_, role))));
    }

    function _roleCount(ICollection collection, address address_, Role role) private view returns (uint256) {
        return collection.readInt(StorageLocation.ENGINE, _addressRoleKey(address_, role));
    }

    function _setAddressRoleCount(ICollection collection, address address_, Role role, uint256 value) private {
        collection.writeInt(StorageLocation.ENGINE, _addressRoleKey(address_, role), value);
    }

    function _incrementAddressRoleCount(ICollection collection, address address_, Role role) private {
        uint256 count = _roleCount(collection, address_, role);
        _setAddressRoleCount(collection, address_, role, count + 1);
    }

    function _decrementAddressRoleCount(ICollection collection, address address_, Role role) private {
        uint256 count = _roleCount(collection, address_, role);
        require(count > 0, "SQUADZ: cannot decrement address role count of 0");
        _setAddressRoleCount(collection, address_, role, count - 1);
    }

    function _validateMint(ICollection collection, Role role) private view {
        if (Collection(address(collection)).owner() == msg.sender) return;
        bool isAdmin = isRole(collection, msg.sender, Role.ADMIN);
        bool isMember = isRole(collection, msg.sender, Role.MEMBER);
        if (role == Role.ADMIN) {
            require(isAdmin == true, "SQUADZ: sender not admin");
        } else {
            require(isAdmin == true || isMember == true, "SQUADZ: sender not admin or member");
        }
    }
}