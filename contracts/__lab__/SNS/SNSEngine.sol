//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IReverseRecords} from "./IReverseRecords.sol";
import {IEngine} from "../../IEngine.sol";
import {IShellFramework, MintEntry} from "../../IShellFramework.sol";
import {IShellERC721, StringStorage, IntStorage, MintOptions, StorageLocation} from "../../IShellERC721.sol";
import {SimpleRoyaltiesEngine} from "../SimpleRoyaltiesEngine.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * Insert standard reference to shell here
 */

/**
 * ===== SIMPLE NAME SYSTEM =====//
 *
 * A simple name system that partially matches the Ethereum Name System's interfaces without implementing the entire system.
 * Simply lets each address claim one name at a time.
 * Intended to be used to let NFTs display user names on Squadz pages on networks where ENS is unavailable (i.e. not mainnet).
 * Matches the same pattern for reverse name look up for ENS' reverse record contract (getNames)
 *
 */

contract SNS is IReverseRecords {
    //===== State =====//

    SNSEngine private immutable _engine;
    IShellFramework public immutable collection;

    //===== Constructor =====//

    constructor(address engine, address collection_) {
        _engine = SNSEngine(engine);
        collection = IShellFramework(collection_);
    }

    //===== External Functions

    function getNames(address[] calldata addresses) external view override returns (string[] memory) {
        string[] memory r = new string[](addresses.length);
        for(uint i = 0; i < addresses.length; i++) {
            uint256 tokenId = _engine.getNameId(collection, addresses[i]);
            string memory name_ = _engine.getNameFromTokenId(collection, tokenId);
            if (bytes(name_).length == 0) {
                continue;
            }
            r[i] = name_;
        }
        return r;
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
    function afterInstallEngine(IShellFramework collection) external {
        require(
            collection.supportsInterface(type(IShellERC721).interfaceId) &&
            collection.supportsInterface(type(IERC721Upgradeable).interfaceId),
            "SNS: collection must support IShellERC721"
        );
        require(msg.sender == address(collection), "SNS: msg.sender not collection");
        address snsAddr = address(new SNS(address(this), address(collection)));
        _setSNS(collection, snsAddr);
        // start with a price too expensive to buy so the owner can do a "fair release" at a lower price later
        setPrice(collection, MAX_INT);
    }

    function afterInstallEngine(IShellFramework, uint256) external pure {
        revert("SNS: cannot install engine to individual tokens");
    }

    function mintAndSet(IShellERC721 collection, string calldata name_) external payable returns (uint256) {
        // TODO re-entrancy guard might be needed in someone can reenter on receiving an ERC721?
        uint256 tokenId = mint(collection, msg.sender, name_);
        setName(collection, msg.sender, name_);
        return tokenId;
    }

    function withdraw(IShellERC721 collection) external {
        address owner = collection.owner();
        uint256 balance = getBalance(collection);
        _setBalance(collection, 0);
        // TODO re-entrancy guard to prevent re-entrancy on receiving ether?
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

    function mint(IShellERC721 collection, address to, string calldata name_) public payable returns (uint256) {
        uint256 price = getPrice(collection);
        require(msg.value == price, "SNS: wrong msg.value");
        _setBalance(collection, getBalance(collection) + price);
        return _mint(collection, to, name_);
    }

    function setName(IShellERC721 collection, address holder, string calldata name_) public {
        uint256 tokenId = _getIdFromName(collection, name_);
        address tokenOwner = collection.ownerOf(tokenId);
        require(tokenOwner == holder, "SNS: name can only be set to its holder");
        address snsAddr = getSNSAddr(collection);
        require(snsAddr != address(0), "SNS: missing SNS address--call init");
        _setName(collection, holder, tokenId);
    }

    function getNames(IShellERC721 collection, address[] calldata holders) public view returns (string[] memory) {
        SNS sns = SNS(getSNSAddr(collection));
        return sns.getNames(holders);
    }

    function getSNSAddr(IShellERC721 collection) public view returns (address) {
        return address(uint160(
            collection.readCollectionInt(StorageLocation.ENGINE, _snsKey())
        ));
    }

    function getPrice(IShellERC721 collection) public view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, _priceKey());
    }

    function setPrice(IShellFramework collection, uint256 price) public {
        require(
            msg.sender == collection.owner() ||
            msg.sender == address(collection),
            "SNS: msg.sender not collection nor collection owner"
        );
        collection.writeCollectionInt(StorageLocation.ENGINE, _priceKey(), price);
    }

    function getBalance(IShellERC721 collection) public view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, _balanceKey(collection));
    }

    function getNameFromTokenId(IShellFramework collection, uint256 tokenId) public view returns (string memory) {
        return collection.readTokenString(StorageLocation.MINT_DATA, tokenId, _idToNameKey());
    }

    function getNameId(IShellFramework collection, address holder) public view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, _nameKey(holder));
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

        StringStorage[] memory stringData = new StringStorage[](1);
        stringData[0].key = _idToNameKey();
        stringData[0].value = name_;
        IntStorage[] memory intData = new IntStorage[](0);

        uint256 tokenId = collection.mint(MintEntry({
            to: to,
            amount: 1,
            options:
                // minimal storage for minimal gas cost
                MintOptions({
                    storeEngine: false,
                    storeMintedTo: false,
                    storeTimestamp: false,
                    storeBlockNumber: false,
                    stringData: stringData,
                    intData: intData
                })
            })
        );

        collection.writeCollectionInt(StorageLocation.ENGINE, name_, tokenId);

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
        collection.writeCollectionInt(
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
        collection.writeCollectionInt(StorageLocation.ENGINE, _balanceKey(collection), value);
    }

    function _nameKey(address holder) private pure returns (string memory) {
        return string(abi.encodePacked(holder));
    }

    function _setName(IShellERC721 collection, address holder, uint256 tokenId) private {
        collection.writeCollectionInt(StorageLocation.ENGINE, _nameKey(holder), tokenId);
    }

    function _idToNameKey() private pure returns (string memory) {
        return "NAME";
    }

    function _getIdFromName(IShellERC721 collection, string calldata name_) private view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, name_);
    }
}
