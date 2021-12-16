//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IEngine.sol";

// Data provided by engine when minting a new token
struct MintOptions {
    bool storeEngine;
    bool storeMintedBy;
    bool storeMintedTo;
    bool storeTimestamp;
    bool storeBlockNumber;
    StringStorage[] stringData;
    IntStorage[] intData;
}

// Each storage location has its own access constraints
enum StorageLocation {
    // can only be set by token owner at any time, mutable
    OWNER,
    // is set by the engine at any time, mutable
    ENGINE,
    // is set by engine during minting, immutable
    MINT_DATA,
    // is set by the framework during minting or collection creation, immutable
    FRAMEWORK
}

struct StringStorage {
    string key;
    string value;
}

struct IntStorage {
    string key;
    uint256 value;
}

// Interface for every collection launched by the framework
interface ICollection {
    // A new engine was installed
    event EngineInstalled(IEngine indexed engine);

    // A string was stored in the collection
    event CollectionStringUpdated(
        StorageLocation indexed location,
        string indexed key,
        string value
    );

    // A string was stored in a token
    event TokenStringUpdated(
        StorageLocation indexed location,
        uint256 indexed tokenId,
        string indexed key,
        string value
    );

    // A uint256 was stored in the collection
    event CollectionIntUpdated(
        StorageLocation indexed location,
        string indexed key,
        uint256 value
    );

    // A uint256 was stored in a token
    event TokenIntUpdated(
        StorageLocation indexed location,
        uint256 indexed tokenId,
        string indexed key,
        uint256 value
    );

    // ---
    // Collection owner (admin) functionaltiy
    // ---

    // Hot swap the collection's engine. Only callable by contract owner
    function installEngine(IEngine engine) external;

    function installedEngine() external view returns (IEngine);

    // ---
    // Engine functionality
    // ---

    // Mint a new token. Only callable by engine
    function mint(address to, MintOptions calldata options)
        external
        returns (uint256);

    // ---
    // Storage writes
    // ---

    // Write a string to collection storage
    function writeString(
        StorageLocation location,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to token storage
    function writeString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to collection storage
    function writeInt(
        StorageLocation location,
        string calldata key,
        uint256 value
    ) external;

    // Write a string to token storage
    function writeInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Storage reads
    // ---

    // Read a string from collection storage
    function readString(StorageLocation location, string calldata key)
        external
        view
        returns (string memory);

    // Read a string from token storage
    function readString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from collection storage
    function readInt(StorageLocation location, string calldata key)
        external
        view
        returns (uint256);

    // Read a uint256 from token storage
    function readInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256);
}
