//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INameResolverLike} from "./INameResolverLike.sol";
import {IRegistrarLike} from "./IRegistrarLike.sol";
import {IReverseRegistrarLike} from "./IReverseRegistrarLike.sol";
import {IReverseRecordsLike} from "./IReverseRecordsLike.sol";
import {IEngine} from "../../IEngine.sol";
import {ICollection, StringStorage, IntStorage, MintOptions, StorageLocation} from "../../ICollection.sol";
import {Collection} from "../../Collection.sol";
import {NoRoyaltiesEngine} from "../../engines/NoRoyaltiesEngine.sol";

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
 *   bytes32 node = IReverseRegistrarLike(reverseRegistrarAddr).node(address);
 *   address resolverAddr = IRegistrarLike(registrarAddr)resolver(node);
 *   string name = INameResolverLike(resolverAddr).name(node);
 * 
 * Or call getNames(address[]) in ReverseRecords.sol, which does this for you
 * 
 * For SNS, all replicated interfaces are on the main SNS address. With ENS, this is not the case.
 */

contract SNS is 
    INameResolverLike, 
    IRegistrarLike, 
    IReverseRegistrarLike,
    IReverseRecordsLike
{
    //===== State =====//

    SNSEngine private immutable _engine;
    ICollection public immutable collection;

    //===== Constructor =====//

    constructor(address engine, address collection_) {
        _engine = SNSEngine(engine);
        collection = ICollection(collection_);
    }

    //===== External Functions

    // From ENS: https://github.com/ensdomains/reverse-records/blob/6ef80ba0a445b3f7cdff7819aaad1efbd8ad22fb/contracts/ReverseRecords.sol
    function getNames(address[] calldata addresses) external view returns (string[] memory r) {
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

    function resolver(bytes32 node_) external view returns (address) {
        // In ENS, this would not always be the same address
        return address(this);
    }

    //===== Public Functions =====//

    function name(bytes32 node_) public view returns (string memory) {
        uint256 tokenId = _engine.getHeldTokenId(collection, node_);
        return _engine.getNameFromId(collection, tokenId);
    }

    // From ENS: https://github.com/ensdomains/ens/blob/ff0f41747c05f1598973b0fe7ad0d9e09565dfcd/contracts/ReverseRegistrar.sol
    function node(address addr) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _engine.sha3HexAddress(addr)));
    }
}

contract SNSEngine is IEngine, NoRoyaltiesEngine {
    //===== External Functions =====//

    // display name for this engine
    function name() external pure returns (string memory) {
        return "SNS v0.0.0";
    }

    function claimName(ICollection collection, string calldata name_) external returns (uint256) {
        address snsAddr = getSNSAddr(collection);
        if (snsAddr == address(0)) {
            snsAddr = address(new SNS(address(this), address(collection)));
            _setSNS(collection, snsAddr);
        }
        return _mint(collection, snsAddr, msg.sender, name_);
    }

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(ICollection collection, uint256 tokenId)
        external
        view
        returns (string memory) {
        return getNameFromId(collection, tokenId);
    }

    // TODO needs burn
    // function swapName(string calldata name) external {}

    // Called by the collection during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    function beforeTokenTransfer(
        ICollection collection,
        address from,
        address to,
        uint256 tokenId
    ) external {
        SNS sns = SNS(getSNSAddr(collection));
        if (from != address(0)) _setHolder(collection, sns.node(from), 0);
        _setHolder(collection, sns.node(to), tokenId);
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

    function getSNSAddr(ICollection collection) public view returns (address) {
        return address(uint160(
            collection.readInt(StorageLocation.ENGINE, _snsKey())
        ));
    }

    function getNameFromId(ICollection collection, uint256 tokenId) public view returns (string memory) {
        return collection.readString(StorageLocation.MINT_DATA, _idToNameKey(tokenId));
    }

    function getHeldTokenId(ICollection collection, bytes32 node) public view returns (uint256) {
        return collection.readInt(StorageLocation.ENGINE, _holderKey(node));
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
        require(getHeldTokenId(collection, SNS(snsAddr).node(to)) == 0, "SNS: address holds a name");

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

    function _holderKey(bytes32 node) private pure returns (string memory) {
        return string(abi.encodePacked(node));
    }

    function _setHolder(ICollection collection, bytes32 node, uint256 tokenId) private {
        collection.writeInt(StorageLocation.ENGINE, _holderKey(node), tokenId);
    }

    function _idToNameKey(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(tokenId));
    }

    function _getIdFromName(ICollection collection, string calldata name_) private view returns (uint256) {
        return collection.readInt(StorageLocation.MINT_DATA, name_);
    }
}