//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./IEngine.sol";
import "./ICollection.sol";

contract Collection is
    ICollection,
    IERC2981,
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable
{
    // Currently installed engine
    IEngine public installedEngine;

    // token id serial number
    uint256 public nextTokenId;

    // all stored strings
    mapping(bytes32 => string) private _stringStorage;

    // all stored ints
    mapping(bytes32 => uint256) private _intStorage;

    function initialize(
        string calldata name,
        string calldata symbol,
        IEngine engine,
        address owner
    ) external initializer {
        // also inits Context, ERC165
        __ERC721_init(name, symbol);

        // purposefully omitting __Ownable_init
        //
        // its init chain only has Context (which is inited in the 721 call
        // above), and for our own init-ing we're setting owner based on the
        // function argument, so no need to assign it twice

        _transferOwnership(owner);
        _installEngine(engine);
        nextTokenId = 1;
    }

    // ---
    // Collection owner (admin) functionaltiy
    // ---

    function installEngine(IEngine engine) external onlyOwner {
        _installEngine(engine);
    }

    function _installEngine(IEngine engine) internal {
        require(
            engine.supportsInterface(type(IEngine).interfaceId),
            "shell: invalid engine"
        );
        installedEngine = engine;
        emit EngineInstalled(engine);
    }

    // ---
    // Engine functionality
    // ---

    function mint(address to, MintOptions calldata options)
        external
        returns (uint256)
    {
        require(_msgSender() == address(installedEngine), "shell: not engine");

        uint256 tokenId = nextTokenId++;
        _mint(to, tokenId);

        // write engine-provided immutable data

        for (uint256 i = 0; i < options.stringData.length; i++) {
            _writeString(
                StorageLocation.MINT_DATA,
                tokenId,
                options.stringData[i].key,
                options.stringData[i].value
            );
        }

        for (uint256 i = 0; i < options.intData.length; i++) {
            _writeInt(
                StorageLocation.MINT_DATA,
                tokenId,
                options.intData[i].key,
                options.intData[i].value
            );
        }

        // write framework immutable data

        if (options.storeEngine) {
            _writeInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "engine",
                uint256(uint160(address(installedEngine)))
            );
        }
        if (options.storeMintedBy) {
            _writeInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "mintedBy",
                uint256(uint160(address(_msgSender())))
            );
        }
        if (options.storeMintedTo) {
            _writeInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "mintedTo",
                uint256(uint160(address(to)))
            );
        }
        if (options.storeTimestamp) {
            _writeInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "timestamp",
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
        }
        if (options.storeBlockNumber) {
            _writeInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "blockNumber",
                block.number
            );
        }

        return tokenId;
    }

    // ---
    // Storage write controller
    // ---

    function writeString(
        StorageLocation location,
        string calldata key,
        string calldata value
    ) external {
        _validateWrite(location);
        _writeString(location, key, value);
    }

    function writeString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external {
        _validateWrite(location, tokenId);
        _writeString(location, tokenId, key, value);
    }

    function writeInt(
        StorageLocation location,
        string calldata key,
        uint256 value
    ) external {
        _validateWrite(location);
        _writeInt(location, key, value);
    }

    function writeInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external {
        _validateWrite(location, tokenId);
        _writeInt(location, tokenId, key, value);
    }

    function _validateWrite(StorageLocation location) private view {
        if (location == StorageLocation.ENGINE) {
            require(
                _msgSender() == address(installedEngine),
                "shell: not engine"
            );
        } else {
            revert("shell: invalid write");
        }
    }

    function _validateWrite(StorageLocation location, uint256 tokenId)
        private
        view
    {
        if (location == StorageLocation.OWNER) {
            require(_msgSender() == ownerOf(tokenId), "shell: not nft owner");
        } else if (location == StorageLocation.ENGINE) {
            require(
                _msgSender() == address(installedEngine),
                "shell: not engine"
            );
        } else {
            revert("shell: invalid write");
        }
    }

    // ---
    // Storage write implementation
    // ---

    function _writeString(
        StorageLocation location,
        string memory key,
        string memory value
    ) internal {
        bytes32 storageKey = keccak256(abi.encodePacked(location, key));
        _stringStorage[storageKey] = value;
        emit CollectionStringUpdated(location, key, value);
    }

    function _writeString(
        StorageLocation location,
        uint256 tokenId,
        string memory key,
        string memory value
    ) internal {
        bytes32 storageKey = keccak256(
            abi.encodePacked(location, tokenId, key)
        );
        _stringStorage[storageKey] = value;
        emit TokenStringUpdated(location, tokenId, key, value);
    }

    function _writeInt(
        StorageLocation location,
        string memory key,
        uint256 value
    ) internal {
        bytes32 storageKey = keccak256(abi.encodePacked(location, key));
        _intStorage[storageKey] = value;
        emit CollectionIntUpdated(location, key, value);
    }

    function _writeInt(
        StorageLocation location,
        uint256 tokenId,
        string memory key,
        uint256 value
    ) internal {
        bytes32 storageKey = keccak256(
            abi.encodePacked(location, tokenId, key)
        );
        _intStorage[storageKey] = value;
        emit TokenIntUpdated(location, tokenId, key, value);
    }

    // ---
    // Event publishing
    // ---

    function publishString(
        PublishChannel channel,
        string calldata topic,
        string calldata value
    ) external {
        _validatePublish(channel);
        emit CollectionStringPublished(channel, topic, value);
    }

    function publishString(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
        string calldata value
    ) external {
        _validatePublish(channel, tokenId);
        emit TokenStringPublished(channel, tokenId, topic, value);
    }

    function publishInt(
        PublishChannel channel,
        string calldata topic,
        uint256 value
    ) external {
        _validatePublish(channel);
        emit CollectionIntPublished(channel, topic, value);
    }

    function publishInt(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
        uint256 value
    ) external {
        _validatePublish(channel, tokenId);
        emit TokenIntPublished(channel, tokenId, topic, value);
    }

    function _validatePublish(PublishChannel channel) private view {
        if (channel == PublishChannel.PUBLIC) {
            return;
        } else if (channel == PublishChannel.OWNER) {
            require(balanceOf(_msgSender()) > 0, "shell: no owned nfts");
        } else if (channel == PublishChannel.ENGINE) {
            require(
                _msgSender() == address(installedEngine),
                "shell: not engine"
            );
        }
    }

    function _validatePublish(PublishChannel channel, uint256 tokenId)
        private
        view
    {
        if (channel == PublishChannel.PUBLIC) {
            return;
        } else if (channel == PublishChannel.OWNER) {
            require(ownerOf(tokenId) == _msgSender(), "shell: not nft owner");
        } else if (channel == PublishChannel.ENGINE) {
            require(
                _msgSender() == address(installedEngine),
                "shell: not engine"
            );
        }
    }

    // ---
    // Storage views
    // ---

    function readString(StorageLocation location, string calldata key)
        external
        view
        returns (string memory)
    {
        bytes32 storageKey = keccak256(abi.encodePacked(location, key));
        return _stringStorage[storageKey];
    }

    function readString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory) {
        bytes32 storageKey = keccak256(
            abi.encodePacked(location, tokenId, key)
        );
        return _stringStorage[storageKey];
    }

    function readInt(StorageLocation location, string calldata key)
        external
        view
        returns (uint256)
    {
        bytes32 storageKey = keccak256(abi.encodePacked(location, key));
        return _intStorage[storageKey];
    }

    function readInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256) {
        bytes32 storageKey = keccak256(
            abi.encodePacked(location, tokenId, key)
        );
        return _intStorage[storageKey];
    }

    // ---
    // Views powered by current engine
    // ---

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return installedEngine.getTokenURI(this, tokenId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return installedEngine.getRoyaltyInfo(this, tokenId, salePrice);
    }

    // ---
    // introspection
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // ---
    // Open Zeppelin ERC721 hook
    // ---

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        try installedEngine.beforeTokenTransfer(this, from, to, tokenId) {
            return;
        } catch {
            // engine reverted, but we don't want to block the transfer
            return;
        }
    }
}
