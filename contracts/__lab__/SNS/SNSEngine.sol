//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {NameResolverLike} from "./NameResolverLike.sol";
import {RegistrarLike} from "./RegistrarLike.sol";
import {ReverseRegistrarLike} from "./ReverseRegistrarLike.sol";
import {ReverseRecordsLike} from "./ReverseRecordsLike.sol";
import {IEngine} from "../../IEngine.sol";
import {IShellFramework} from "../../IShellFramework.sol";
import {IShellERC721, StringStorage, IntStorage, MintOptions, StorageLocation} from "../../IShellERC721.sol";
// import {ShellFramework} from "../../ShellFramework.sol";
import {SimpleRoyaltiesEngine} from "../SimpleRoyaltiesEngine.sol";

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
    IShellFramework public immutable collection;

    //===== Constructor =====//

    constructor(address engine, address collection_) {
        _engine = SNSEngine(engine);
        collection = IShellFramework(collection_);
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

    function resolver(bytes32) external view override returns (address) {
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

contract SNSEngine is IEngine, SimpleRoyaltiesEngine {
    //===== State =====//

    uint256 constant MAX_INT = 2**256-1;

    //===== External Functions =====//

    // Get the name for this engine
    function getEngineName() external pure returns (string memory) {
        return "SNS v0.0.0";
    }

    // Called by the framework following an engine install. Can be used by the
    // engine to block (by reverting) installation if needed.
    // The engine MUST assert msg.sender == collection address!!
    function afterInstallEngine(IShellFramework collection) external collectionOwnerOnly(collection) {
        address snsAddr = address(new SNS(address(this), address(collection)));
        _setSNS(collection, snsAddr);
        // start with a price too expensive to buy so the owner can do a "fair release" at a lower price and later time
        setPrice(collection, MAX_INT);
    } 

    function mintAndSet(IShellERC721 collection, string calldata name_) external payable returns (uint256) {
        uint256 tokenId = mint(collection, name_);
        setName(collection, name_, msg.sender);
        return tokenId;
    }

    function withdraw(IShellERC721 collection) external {
        address owner = collection.owner();
        uint256 balance = getBalance(collection);
        _setBalance(collection, 0);
        // TODO re-entrancy guard
        // TODO can we get rid of the unused variable warning for data here?
        (bool sent, ) = owner.call{value: balance}("");
        require(sent, "Failed to send Ether");
        // TODO send WETH if ETH fails
    }

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory) {
        return getNameFromTokenId(collection, tokenId);
    }

    // Called by the framework during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    // The engine MUST assert msg.sender == collection address!!
    function beforeTokenTransfer(
        IShellFramework,
        address,
        address,
        address,
        uint256[] memory,
        uint256[] memory
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

    //===== Public Functions

    function mint(IShellERC721 collection, string calldata name_) public payable returns (uint256) {
        uint256 price = getPrice(collection);
        require(msg.value == price, "SNS: wrong msg.value");
        _setBalance(collection, getBalance(collection) + price);
        return _mint(collection, msg.sender, name_);
    }

    function setName(IShellERC721 collection, string calldata name_, address holder) public {
        uint256 tokenId = _getIdFromName(collection, name_);
        address tokenOwner = collection.ownerOf(tokenId);
        require(tokenOwner == holder, "SNS: name can only be set to its holder");
        address snsAddr = getSNSAddr(collection);
        require(snsAddr != address(0), "SNS: missing SNS address--call init");
        _setName(collection, SNS(snsAddr).node(holder), tokenId);
    }

    function getSNSAddr(IShellERC721 collection) public view returns (address) {
        return address(uint160(
            collection.readInt(StorageLocation.ENGINE, _snsKey())
        ));
    }

    function getPrice(IShellERC721 collection) public view returns (uint256) {
        return collection.readInt(StorageLocation.ENGINE, _priceKey());
    }

    function setPrice(IShellFramework collection, uint256 price) public collectionOwnerOnly(collection) {
        collection.writeInt(StorageLocation.ENGINE, _priceKey(), price);
    }

    function getBalance(IShellERC721 collection) public view returns (uint256) {
        return collection.readInt(StorageLocation.ENGINE, _balanceKey(collection));
    }

    function getNameFromTokenId(IShellFramework collection, uint256 tokenId) public view returns (string memory) {
        return collection.readString(StorageLocation.MINT_DATA, _idToNameKey(tokenId));
    }

    function getNameId(IShellFramework collection, bytes32 node) public view returns (uint256) {
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

    function _mint(IShellERC721 collection, address to, string calldata name_) private returns (uint256) {
        require(_getIdFromName(collection, name_) == 0, "SNS: name already minted");

        uint256 nextTokenId = collection.nextTokenId();
        StringStorage[] memory stringData = new StringStorage[](1);
        stringData[0].key = _idToNameKey(nextTokenId);
        stringData[0].value = name_;
        IntStorage[] memory intData = new IntStorage[](1);
        intData[0].key = name_;
        intData[0].value = nextTokenId;

        uint256 tokenId = collection.mint(
            to,
            // minimal storage for minimal gas cost
            MintOptions({
                storeEngine: false,
                storeMintedTo: false,
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

    function _setSNS(IShellFramework collection, address snsAddr) private {
        collection.writeInt(
            StorageLocation.ENGINE,
            _snsKey(),
            uint256(uint160(snsAddr))
        );
    }

    function _priceKey() private pure returns (string memory) {
        return "PRICE";
    }

    function _balanceKey(IShellERC721 collection) private pure returns (string memory) {
        return string(abi.encodePacked(address(collection), "BALANCE"));
    }

    function _setBalance(IShellERC721 collection, uint256 value) private {
        collection.writeInt(StorageLocation.ENGINE, _balanceKey(collection), value);
    }

    function _nameKey(bytes32 node) private pure returns (string memory) {
        return string(abi.encodePacked(node));
    }

    function _setName(IShellERC721 collection, bytes32 node, uint256 tokenId) private {
        collection.writeInt(StorageLocation.ENGINE, _nameKey(node), tokenId);
    }

    function _idToNameKey(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(tokenId));
    }

    function _getIdFromName(IShellERC721 collection, string calldata name_) private view returns (uint256) {
        return collection.readInt(StorageLocation.MINT_DATA, name_);
    }

    //===== Modifiers =====//

    modifier collectionOwnerOnly(IShellFramework collection) {
        require(msg.sender == collection.owner(), "SNS: msg.sender not collection owner");
        _;
    }
}