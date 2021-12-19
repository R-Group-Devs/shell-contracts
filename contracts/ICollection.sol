//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
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
    // set by token owner at any time, mutable
    OWNER,
    // set by the engine at any time, mutable
    ENGINE,
    // set by engine during minting, immutable
    MINT_DATA,
    // set by the framework during minting or collection creation, immutable
    FRAMEWORK
}

enum PublishChannel {
    // events created by anybody
    PUBLIC,
    // events created by token owner
    OWNER,
    // events created by engine
    ENGINE
}

struct StringStorage {
    string key;
    string value;
}

struct IntStorage {
    string key;
    uint256 value;
}

// Interface for every collection launched by the framework. Concrete
// implementations must return true on ERC165 checks for this interface
interface ICollection is IERC165, IERC2981 {
    // ---
    // Framework events
    // ---

    // A new engine was installed
    event EngineInstalled(IEngine indexed engine);

    // ---
    // Storage events
    // ---

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
    // Published events
    // ---

    // A string was published from the collection
    event CollectionStringPublished(
        PublishChannel indexed location,
        string indexed key,
        string value
    );

    // A string was published from a token
    event TokenStringPublished(
        PublishChannel indexed location,
        uint256 indexed tokenId,
        string indexed key,
        string value
    );

    // A uint256 was published from the collection
    event CollectionIntPublished(
        PublishChannel indexed location,
        string indexed key,
        uint256 value
    );

    // A uint256 was published from a token
    event TokenIntPublished(
        PublishChannel indexed location,
        uint256 indexed tokenId,
        string indexed key,
        uint256 value
    );

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
    // Event publishing
    // ---

    // publish a string from the collection
    function publishString(
        PublishChannel channel,
        string calldata topic,
        string calldata value
    ) external;

    // publish a string from a specific token
    function publishString(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
        string calldata value
    ) external;

    // publish a uint256 from the collection
    function publishInt(
        PublishChannel channel,
        string calldata topic,
        uint256 value
    ) external;

    // publish a uint256 from a specific token
    function publishInt(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
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
