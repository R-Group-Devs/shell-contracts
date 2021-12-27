//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./libraries/IOwnable.sol";
import "./IEngine.sol";

// storage flag
enum StorageLocation {
    INVALID,
    // set by the engine at any time, mutable
    ENGINE,
    // set by the engine during minting, immutable
    MINT_DATA,
    // set by the framework during minting or collection creation, immutable
    FRAMEWORK
}

// publish flag
enum PublishChannel {
    INVALID,
    // events created by anybody
    PUBLIC,
    // events created by engine
    ENGINE
}

// string key / value
struct StringStorage {
    string key;
    string value;
}

// int key / value
struct IntStorage {
    string key;
    uint256 value;
}

struct MintEntry {
    address to;
    uint256 amount;
    MintOptions options;
}

// Data provided by engine when minting a new token
struct MintOptions {
    bool storeEngine;
    bool storeMintedTo;
    bool storeTimestamp;
    bool storeBlockNumber;
    StringStorage[] stringData;
    IntStorage[] intData;
}

// Interface for every collection launched by shell.
// Concrete implementations must return true on ERC165 checks for this interface
// (as well as erc165 / 2981)
// interfaceId = 0x46877bbc
interface IShellFramework is IERC165, IERC2981, IOwnable {
    // ---
    // Framework events
    // ---

    // A new engine was installed
    event EngineInstalled(IEngine engine);

    // A new engine was installed for a token
    event TokenEngineInstalled(uint256 tokenId, IEngine engine);

    // ---
    // Storage events
    // ---

    // A string was stored in the collection
    event CollectionStringUpdated(
        StorageLocation location,
        string key,
        string value
    );

    // A string was stored in a token
    event TokenStringUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        string value
    );

    // A uint256 was stored in the collection
    event CollectionIntUpdated(
        StorageLocation location,
        string key,
        uint256 value
    );

    // A uint256 was stored in a token
    event TokenIntUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        uint256 value
    );

    // ---
    // Published events
    // ---

    // A string was published from the collection
    event CollectionStringPublished(
        PublishChannel location,
        string key,
        string value
    );

    // A string was published from a token
    event TokenStringPublished(
        PublishChannel location,
        uint256 tokenId,
        string key,
        string value
    );

    // A uint256 was published from the collection
    event CollectionIntPublished(
        PublishChannel location,
        string key,
        uint256 value
    );

    // A uint256 was published from a token
    event TokenIntPublished(
        PublishChannel location,
        uint256 tokenId,
        string key,
        uint256 value
    );

    // ---
    // Collection base
    // ---

    // called immediately after cloning
    function initialize(
        string calldata name,
        string calldata symbol,
        IEngine engine,
        address owner
    ) external;

    // ---
    // General collection info / metadata
    // ---

    // collection name
    function name() external view returns (string memory);

    // collection name
    function symbol() external view returns (string memory);

    // next token id serial number
    function nextTokenId() external view returns (uint256);

    // ---
    // NFT owner functionaltiy
    // ---

    // override a token's engine. Only callable by NFT owner
    function installTokenEngine(uint256 tokenId, IEngine engine) external;

    // ---
    // Collection owner (admin) functionaltiy
    // ---

    // Hot swap the collection's engine. Only callable by contract owner
    function installEngine(IEngine engine) external;

    // the currently installed engine for this collection
    function installedEngine() external view returns (IEngine);

    // ---
    // Engine functionality
    // ---

    // mint new tokens. Only callable by engine
    function mint(MintEntry calldata entry) external returns (uint256);

    // mint new tokens. Only callable by engine
    function batchMint(MintEntry[] calldata entries)
        external
        returns (uint256[] memory);

    // ---
    // Storage writes
    // ---

    // Write a string to collection storage
    function writeCollectionString(
        StorageLocation location,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to token storage
    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to collection storage
    function writeCollectionInt(
        StorageLocation location,
        string calldata key,
        uint256 value
    ) external;

    // Write a string to token storage
    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Event publishing
    // ---

    // publish a string from the collection
    function publishCollectionString(
        PublishChannel channel,
        string calldata topic,
        string calldata value
    ) external;

    // publish a string from a specific token
    function publishTokenString(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
        string calldata value
    ) external;

    // publish a uint256 from the collection
    function publishCollectionInt(
        PublishChannel channel,
        string calldata topic,
        uint256 value
    ) external;

    // publish a uint256 from a specific token
    function publishTokenInt(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
        uint256 value
    ) external;

    // ---
    // Storage reads
    // ---

    // Read a string from collection storage
    function readCollectionString(StorageLocation location, string calldata key)
        external
        view
        returns (string memory);

    // Read a string from token storage
    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from collection storage
    function readCollectionInt(StorageLocation location, string calldata key)
        external
        view
        returns (uint256);

    // Read a uint256 from token storage
    function readTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256);
}
