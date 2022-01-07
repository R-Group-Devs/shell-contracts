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
    FRAMEWORK,
    // set by the engine at any time, not associated with a particular token,
    // siloed to a specific fork
    FORK
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

// data provided when minting a new token
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

// Information about a fork
struct Fork {
    IEngine engine;
    address owner;
}

// Interface for every collection launched by shell.
// Concrete implementations must return true on ERC165 checks for this interface
// (as well as erc165 / 2981)
// interfaceId = TBD
interface IShellFramework is IERC165, IERC2981 {
    // ---
    // Framework errors
    // ---

    // an engine was provided that did no pass the expected erc165 checks
    error InvalidEngine();

    // a write was attempted that is not allowed
    error WriteNotAllowed();

    // an operation was attempted but msg.sender was not the expected engine
    error SenderNotEngine();

    // an operation was attempted but msg.sender was not the fork owner
    error SenderNotForkOwner();

    // an operation was attempted but msg.sender was not the token owner
    error SenderNotTokenOwner();

    // ---
    // Framework events
    // ---

    // a fork was created
    event ForkCreated(uint256 forkId, IEngine engine, address owner);

    // a fork had a new engine installed
    event ForkEngineUpdated(uint256 forkId, IEngine engine);

    // a fork had a new owner set
    event ForkOwnerUpdated(uint256 forkId, address owner);

    // a token has been set to a new fork
    event TokenForked(uint256 tokenId, uint256 forkId);

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

    // collection owner (fork 0 owner)
    function owner() external view returns (address);

    // collection name
    function name() external view returns (string memory);

    // collection name
    function symbol() external view returns (string memory);

    // next token id serial number
    function nextTokenId() external view returns (uint256);

    // next fork id serial number
    function nextForkId() external view returns (uint256);

    // ---
    // Fork functionality
    // ---

    // Create a new fork with a specific engine, fork all the tokenIds to the
    // new engine, and return the fork ID
    function createFork(
        IEngine engine,
        address owner,
        uint256[] calldata tokenIds
    ) external returns (uint256);

    // Set the engine for a specific fork. Must be fork owner
    function setForkEngine(uint256 forkId, IEngine engine) external;

    // Set the fork owner. Must be fork owner
    function setForkOwner(uint256 forkId, address owner) external;

    // Set the fork of a specific token. Must be token owner
    function forkToken(uint256 tokenId, uint256 forkId) external;

    // ---
    // Fork views
    // ---

    // Get information about a fork
    function getFork(uint256 forkId) external view returns (Fork memory);

    // Get the collection / canonical engine. getFork(0).engine
    function getForkEngine(uint256 forkId) external view returns (IEngine);

    // Get a token's fork ID
    function getTokenForkId(uint256 tokenId) external view returns (uint256);

    // Get a token's engine. getFork(getTokenForkId(tokenId)).engine
    function getTokenEngine(uint256 tokenId) external view returns (IEngine);

    // ---
    // Engine functionality
    // ---

    // mint new tokens. Only callable by collection engine
    function mint(MintEntry calldata entry) external returns (uint256);

    // mint new tokens. Only callable by collection engine
    function batchMint(MintEntry[] calldata entries)
        external
        returns (uint256[] memory);

    // ---
    // Storage writes
    // ---

    // Write a string to collection storage. Only callable by collection engine
    function writeForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to collection storage. Only callable by collection engine
    function writeForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        uint256 value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Storage reads
    // ---

    // Read a string from collection storage
    function readForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from collection storage
    function readForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (uint256);

    // Read a string from token storage
    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from token storage
    function readTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256);
}
