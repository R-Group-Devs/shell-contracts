//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {NameResolverLike} from "./NameResolverLike.sol";
import {RegistrarLike} from "./RegistrarLike.sol";
import {ReverseRegistrarLike} from "./ReverseRegistrarLike.sol";
import {ReverseRecordsLike} from "./ReverseRecordsLike.sol";
import {IEngine} from "../../IEngine.sol";
import {ICollection, StringStorage, IntStorage, MintOptions, StorageLocation} from "../../ICollection.sol";
import {Collection} from "../../Collection.sol";

/**
 * Insert standard reference to shell here
 */

/**
 * ===== SIMPLE NAME SYSTEM =====//
 *
 * A simple name system that partially matches the Ethereum Name System's interfaces without implementing the entire system.
 * Simply lets each address claim one name at a time.
 * Intended to be used to let NFTs display user names on Squadz pages on networks where ENS is unavailable (i.e. not mainnet). 
 * Matches the same pattern for reverse name look up for ENS.
 * 
 * Process to look up a name from an address:
 *   bytes32 node = ReverseRegistrarLike(reverseRegistrarAddr).node(address);
 *   address resolverAddr = RegistrarLike(registrarAddr)resolver(node);
 *   string name = NameResolverLike(resolverAddr).name(node);
 * 
 * Or call getNames(address[]) in ReverseRecords.sol, which does this for you
 * 
 * For SNS, all replicated interfaces are on the main SNS address. With ENS, this is not the case.
 */

contract SNS is 
    NameResolverLike, 
    RegistrarLike, 
    ReverseRegistrarLike,
    ReverseRecordsLike
{
    //===== State =====//

    SNSEngine private immutable _engine;
    ICollection public immutable collection;
    uint256 public price;

    //===== Constructor =====//

    constructor(address engine, address collection_, uint256 price_) {
        _engine = SNSEngine(engine);
        collection = ICollection(collection_);
        price = price_;
    }

    //===== External Functions

    // From ENS: https://github.com/ensdomains/reverse-records/blob/6ef80ba0a445b3f7cdff7819aaad1efbd8ad22fb/contracts/ReverseRecords.sol
    function getNames(address[] calldata addresses) external view override returns (string[] memory r) {
        r = new string[](addresses.length);
        for(uint i = 0; i < addresses.length; i++) {
            bytes32 node_ = node(addresses[i]);
            string memory name_ = name(node_);
            if (bytes(name_).length == 0) {
                continue;
            }
            r[i] = name_;
        }
        return r;
    }

    function resolver(bytes32 node_) external view override returns (address) {
        // In ENS, this would not always be the same address
        return address(this);
    }

    //===== Public Functions =====//

    function name(bytes32 node_) public view override returns (string memory) {
        uint256 tokenId = _engine.getNameId(collection, node_);
        return _engine.getNameFromTokenId(collection, tokenId);
    }

    // From ENS: https://github.com/ensdomains/ens/blob/ff0f41747c05f1598973b0fe7ad0d9e09565dfcd/contracts/ReverseRegistrar.sol
    function node(address addr) public view override returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _engine.sha3HexAddress(addr)));
    }
}

// TODO set some royalties in constructor

contract SNSEngine is IEngine {
    //===== External Functions =====//

    // display name for this engine
    function name() external pure returns (string memory) {
        return "SNS v0.0.0";
    }

    function init(
        ICollection collection, 
        uint256 price, 
        address royaltyReceiver, 
        uint256 royaltyAmount
    ) collectionOwnerOnly(collection) external {
        address snsAddr = address(new SNS(address(this), address(collection), price));
        _setSNS(collection, snsAddr);
        _setPrice(collection, price);
        if (royaltyReceiver != address(0) || royaltyAmount != 0) {
            setRoyaltyInfo(collection, royaltyReceiver, royaltyAmount);
        }
    }

    function mintAndSet(ICollection collection, string calldata name_) external payable returns (uint256) {
        uint256 tokenId = mint(collection, name_);
        setName(collection, name_, msg.sender);
        return tokenId;
    }

    function withdraw(ICollection collection) external {
        address owner = Collection(address(collection)).owner();
        uint256 balance = getBalance(collection);
        _setBalance(collection, 0);
        // TODO re-entrancy guard
        // TODO can we get rid of the unused variable warning for data here?
        (bool sent, bytes memory data) = owner.call{value: balance}("");
        require(sent, "Failed to send Ether");
        // TODO send WETH if ETH fails
    }

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(ICollection collection, uint256 tokenId)
        external
        view
        returns (string memory) {
        return getNameFromTokenId(collection, tokenId);
    }

    // TODO needs burn

    // Called by the collection during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    function beforeTokenTransfer(
        ICollection collection,
        address from,
        address to,
        uint256 tokenId
    ) external pure {
        // TODO make it optional to add implementation here?
        return;
    }

    /**
     * From ENS: https://github.com/ensdomains/ens/blob/ff0f41747c05f1598973b0fe7ad0d9e09565dfcd/contracts/ReverseRegistrar.sol
     */
    function sha3HexAddress(address addr) external pure returns (bytes32 ret) {
        addr;
        ret; // Stop warning us about unused variables
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

            for { let i := 40 } gt(i, 0) { } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

    function getRoyaltyInfo(
        ICollection collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = address(uint160(
            collection.readInt(StorageLocation.ENGINE, _royaltyReceiverKey(collection))
        ));
        uint256 basisPoints = collection.readInt(StorageLocation.ENGINE, _royaltyBasisKey(collection));
        royaltyAmount = salePrice * basisPoints / 10000;
    }

    //===== Public Functions

    function setRoyaltyInfo(
        ICollection collection, 
        address receiver, 
        uint256 royaltyBasisPoints
    ) public collectionOwnerOnly(collection) {
        collection.writeInt(
            StorageLocation.ENGINE, 
            _royaltyReceiverKey(collection), 
            uint256(uint160(receiver))
        );
        collection.writeInt(StorageLocation.ENGINE, _royaltyBasisKey(collection), royaltyBasisPoints);
    }

    function mint(ICollection collection, string calldata name_) public payable returns (uint256) {
        address snsAddr = getSNSAddr(collection);
        require(snsAddr != address(0), "SNS: missing SNS address--call init");
        uint256 price = getPrice(collection);
        require(msg.value == price, "SNS: wrong msg.value");
        _setBalance(collection, getBalance(collection) + price);
        return _mint(collection, snsAddr, msg.sender, name_);
    }

    function setName(ICollection collection, string calldata name_, address holder) public {
        uint256 tokenId = _getIdFromName(collection, name_);
        address tokenOwner = Collection(address(collection)).ownerOf(tokenId);
        require(tokenOwner == holder, "SNS: name can only be set to its holder");
        address snsAddr = getSNSAddr(collection);
        require(snsAddr != address(0), "SNS: missing SNS address--call init");
        _setName(collection, SNS(snsAddr).node(holder), tokenId);
    }

    function getSNSAddr(ICollection collection) public view returns (address) {
        return address(uint160(
            collection.readInt(StorageLocation.ENGINE, _snsKey())
        ));
    }

    function getPrice(ICollection collection) public view returns (uint256) {
        return collection.readInt(StorageLocation.ENGINE, _priceKey());
    }

    function getBalance(ICollection collection) public view returns (uint256) {
        return collection.readInt(StorageLocation.ENGINE, _balanceKey(collection));
    }

    function getNameFromTokenId(ICollection collection, uint256 tokenId) public view returns (string memory) {
        return collection.readString(StorageLocation.MINT_DATA, _idToNameKey(tokenId));
    }

    function getNameId(ICollection collection, bytes32 node) public view returns (uint256) {
        return collection.readInt(StorageLocation.ENGINE, _nameKey(node));
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

    //===== Private Functions =====//

    function _mint(ICollection collection, address snsAddr, address to, string calldata name_) private returns (uint256) {
        require(_getIdFromName(collection, name_) == 0, "SNS: name already minted");

        uint256 predictedTokenId = Collection(address(collection)).nextTokenId() + 1;
        StringStorage[] memory stringData = new StringStorage[](1);
        stringData[0].key = _idToNameKey(predictedTokenId);
        stringData[0].value = name_;
        IntStorage[] memory intData = new IntStorage[](1);
        intData[0].key = name_;
        intData[0].value = predictedTokenId;

        uint256 tokenId = collection.mint(
            to,
            // minimal storage for minimal gas cost
            MintOptions({
                storeEngine: false,
                storeMintedTo: false,
                storeMintedBy: false,
                storeTimestamp: false,
                storeBlockNumber: false,
                stringData: stringData,
                intData: intData
            })
        );

        return tokenId;
    }

    // needs burn
    // function _burnNameOf(address nameHolder) private {}

    // needs burn
    // function _burnName(string calldata name) private {}

    function _snsKey() private pure returns (string memory) {
        return "SNS";
    }

    function _setSNS(ICollection collection, address snsAddr) private {
        collection.writeInt(
            StorageLocation.ENGINE,
            _snsKey(),
            uint256(uint160(snsAddr))
        );
    }

    function _royaltyReceiverKey(ICollection collection) private pure returns (string memory) {
        return string(abi.encodePacked(address(collection), "ROYALTY_RECEIVER"));
    }

    function _royaltyBasisKey(ICollection collection) private pure returns (string memory) {
        return string(abi.encodePacked(address(collection), "ROYALTY_BASIS"));
    }

    function _priceKey() private pure returns (string memory) {
        return "PRICE";
    }

    function _setPrice(ICollection collection, uint256 price) private {
        collection.writeInt(StorageLocation.ENGINE, _priceKey(), price);
    }

    function _balanceKey(ICollection collection) private pure returns (string memory) {
        return string(abi.encodePacked(address(collection), "BALANCE"));
    }

    function _setBalance(ICollection collection, uint256 value) private {
        collection.writeInt(StorageLocation.ENGINE, _balanceKey(collection), value);
    }

    function _nameKey(bytes32 node) private pure returns (string memory) {
        return string(abi.encodePacked(node));
    }

    function _setName(ICollection collection, bytes32 node, uint256 tokenId) private {
        collection.writeInt(StorageLocation.ENGINE, _nameKey(node), tokenId);
    }

    function _idToNameKey(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(tokenId));
    }

    function _getIdFromName(ICollection collection, string calldata name_) private view returns (uint256) {
        return collection.readInt(StorageLocation.MINT_DATA, name_);
    }

    //===== Modifiers =====//

    modifier collectionOwnerOnly(ICollection collection) {
        require(msg.sender == Collection(address(collection)).owner(), "SNS: msg.sender not collection owner");
        _;
    }
}