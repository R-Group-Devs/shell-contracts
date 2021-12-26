//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/Ownable.sol";
import "./IShellFramework.sol";
import "./IShellERC1155.sol";

// Abstract implementation of the shell framework interface -- can be used as a
// base for all shell collections
abstract contract ShellFramework is IShellFramework, Initializable, Ownable {
    // Currently installed engine
    IEngine public installedEngine;

    // all stored strings
    mapping(bytes32 => string) private _stringStorage;

    // all stored ints
    mapping(bytes32 => uint256) private _intStorage;

    // per-token engine overrides
    mapping(uint256 => IEngine) private _engineOverrides;

    // ensure that the deployed implementation cannot be initialized after
    // deployment. Clones do not trigger the constructor but are manually
    // initted by ShellFactory
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    // used to initialize the clone
    // solhint-disable-next-line func-name-mixedcase
    function __ShellFramework_init(IEngine engine, address owner)
        internal
        onlyInitializing
    {
        _transferOwnership(owner);
        _installEngine(engine);
    }

    // ---
    // NFT owner functionaltiy
    // ---

    function _installTokenEngine(uint256 tokenId, IEngine engine) internal {
        require(
            engine.supportsInterface(type(IEngine).interfaceId),
            "shell: invalid engine"
        );
        _engineOverrides[tokenId] = engine;
        engine.afterInstallEngine(this, tokenId);
        emit TokenEngineInstalled(tokenId, engine);
    }

    // ---
    // Collection owner (admin) functionaltiy
    // ---

    function installEngine(IEngine engine) external onlyOwner {
        _installEngine(engine);
    }

    function _installEngine(IEngine engine) private {
        require(
            engine.supportsInterface(type(IEngine).interfaceId),
            "shell: invalid engine"
        );
        installedEngine = engine;
        engine.afterInstallEngine(this);
        emit EngineInstalled(engine);
    }

    // ---
    // Standard mint functionality
    // ---

    function _writeMintData(uint256 tokenId, MintEntry calldata entry)
        internal
    {
        // write engine-provided immutable data

        for (uint256 i = 0; i < entry.options.stringData.length; i++) {
            _writeTokenString(
                StorageLocation.MINT_DATA,
                tokenId,
                entry.options.stringData[i].key,
                entry.options.stringData[i].value
            );
        }

        for (uint256 i = 0; i < entry.options.intData.length; i++) {
            _writeTokenInt(
                StorageLocation.MINT_DATA,
                tokenId,
                entry.options.intData[i].key,
                entry.options.intData[i].value
            );
        }

        // write framework immutable data

        if (entry.options.storeEngine) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "engine",
                uint256(uint160(address(installedEngine)))
            );
        }
        if (entry.options.storeMintedTo) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "mintedTo",
                uint256(uint160(address(entry.to)))
            );
        }
        if (entry.options.storeTimestamp) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "timestamp",
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
        }
        if (entry.options.storeBlockNumber) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "blockNumber",
                block.number
            );
        }
    }

    // ---
    // Storage write controller (for engine)
    // ---

    function writeCollectionString(
        StorageLocation location,
        string calldata key,
        string calldata value
    ) external {
        _validateCollectionWrite(location);
        _writeCollectionString(location, key, value);
    }

    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external {
        _validateTokenWrite(location, tokenId);
        _writeTokenString(location, tokenId, key, value);
    }

    function writeCollectionInt(
        StorageLocation location,
        string calldata key,
        uint256 value
    ) external {
        _validateCollectionWrite(location);
        _writeCollectionInt(location, key, value);
    }

    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external {
        _validateTokenWrite(location, tokenId);
        _writeTokenInt(location, tokenId, key, value);
    }

    function _validateCollectionWrite(StorageLocation location) private view {
        require(
            location == StorageLocation.ENGINE,
            "shell: invalid storage write"
        );
        require(msg.sender == address(installedEngine), "shell: not engine");
    }

    function _validateTokenWrite(StorageLocation location, uint256 tokenId)
        private
        view
    {
        require(
            location == StorageLocation.ENGINE,
            "shell: invalid storage write"
        );

        // if override is set, must match msg sender
        IEngine ownerOverride = _engineOverrides[tokenId];
        bool isOverridden = ownerOverride != IEngine(address(0));

        if (isOverridden && msg.sender == address(ownerOverride)) {
            return;
        } else if (msg.sender == address(installedEngine)) {
            return;
        }

        revert("shell: not engine");
    }

    // ---
    // Storage write implementation
    // ---

    function _writeCollectionString(
        StorageLocation location,
        string memory key,
        string memory value
    ) internal {
        bytes32 storageKey = keccak256(abi.encodePacked(location, key));
        _stringStorage[storageKey] = value;
        emit CollectionStringUpdated(location, key, value);
    }

    function _writeTokenString(
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

    function _writeCollectionInt(
        StorageLocation location,
        string memory key,
        uint256 value
    ) internal {
        bytes32 storageKey = keccak256(abi.encodePacked(location, key));
        _intStorage[storageKey] = value;
        emit CollectionIntUpdated(location, key, value);
    }

    function _writeTokenInt(
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

    function publishCollectionString(
        PublishChannel channel,
        string calldata topic,
        string calldata value
    ) external {
        _validateCollectionPublish(channel);
        emit CollectionStringPublished(channel, topic, value);
    }

    function publishTokenString(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
        string calldata value
    ) external {
        _validateTokenPublish(channel, tokenId);
        emit TokenStringPublished(channel, tokenId, topic, value);
    }

    function publishCollectionInt(
        PublishChannel channel,
        string calldata topic,
        uint256 value
    ) external {
        _validateCollectionPublish(channel);
        emit CollectionIntPublished(channel, topic, value);
    }

    function publishTokenInt(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
        uint256 value
    ) external {
        _validateTokenPublish(channel, tokenId);
        emit TokenIntPublished(channel, tokenId, topic, value);
    }

    function _validateCollectionPublish(PublishChannel channel) private view {
        if (channel == PublishChannel.PUBLIC) {
            return;
        } else if (channel == PublishChannel.ENGINE) {
            require(
                msg.sender == address(installedEngine),
                "shell: not engine"
            );
        }
        revert("shell: invalid publish");
    }

    function _validateTokenPublish(PublishChannel channel, uint256 tokenId)
        private
        view
    {
        if (channel == PublishChannel.PUBLIC) {
            return;
        }
        if (channel == PublishChannel.ENGINE) {
            // if override is set, must match msg sender
            IEngine ownerOverride = _engineOverrides[tokenId];
            bool isOverridden = ownerOverride != IEngine(address(0));

            if (isOverridden && msg.sender == address(ownerOverride)) {
                return;
            } else if (msg.sender == address(installedEngine)) {
                return;
            }

            revert("shell: not engine");
        }

        revert("shell: invalid publish");
    }

    // ---
    // Storage views
    // ---

    function readCollectionString(StorageLocation location, string calldata key)
        external
        view
        returns (string memory)
    {
        bytes32 storageKey = keccak256(abi.encodePacked(location, key));
        return _stringStorage[storageKey];
    }

    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory) {
        bytes32 storageKey = keccak256(
            abi.encodePacked(location, tokenId, key)
        );
        return _stringStorage[storageKey];
    }

    function readCollectionInt(StorageLocation location, string calldata key)
        external
        view
        returns (uint256)
    {
        bytes32 storageKey = keccak256(abi.encodePacked(location, key));
        return _intStorage[storageKey];
    }

    function readTokenInt(
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
        override
        returns (bool)
    {
        return
            interfaceId == type(IShellFramework).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
