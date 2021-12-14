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
    Uint256Storage[] uint256Data;
}

struct StringStorage {
    string key;
    string value;
}

struct Uint256Storage {
    string key;
    uint256 value;
}

// Interface for every collection launched by the framework
interface ICollection {
    // A new engine was installed
    event EngineInstalled(IEngine indexed engine);

    // Immutable data set during minting
    event MintDataStringSet(
        uint256 indexed tokenId,
        string indexed key,
        string indexed value
    );

    // Token owner has updated a stored string
    event OwnerStringSet(
        uint256 indexed tokenId,
        string indexed key,
        string indexed value
    );

    // Engine has updated a stored string
    event EngineStringSet(
        uint256 indexed tokenId,
        string indexed key,
        string indexed value
    );

    // Engine has updated a global stored string
    event GlobalEngineStringSet(string indexed key, string indexed value);

    // Immutable data set during mint
    event MintDataUint256Set(
        uint256 indexed tokenId,
        string indexed key,
        uint256 indexed value
    );

    // Token owner has updated a stored uint256
    event OwnerUint256Set(
        uint256 indexed tokenId,
        string indexed key,
        uint256 indexed value
    );

    // Engine has updated a stored uint256
    event EngineUint256Set(
        uint256 indexed tokenId,
        string indexed key,
        uint256 indexed value
    );

    // Engine has updated a global stored uint256
    event GlobalEngineUint256Set(string indexed key, uint256 indexed value);

    // ---
    // Collection owner (admin) functionaltiy
    // ---

    // Hot swap the collection's engine. Only callable by contract owner
    function installEngine(IEngine engine_) external;

    // ---
    // NFT Owner functionality
    // ---

    // Read a string from owner storage
    function ownerString(uint256 tokenId, string calldata key)
        external
        returns (string memory);

    // Read a uint256 from owner storage
    function ownerUint256(uint256 tokenId, string calldata key)
        external
        returns (uint256);

    // Write string data to owner storage. Only callable by nft owner
    function writeOwnerString(
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write uint256 data to owner storage. Only callable by nft owner
    function writeOwnerUint256(
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Engine framework
    // ---

    // Read a string from global engine storage
    function globalEngineString(string calldata key)
        external
        view
        returns (string memory);

    // Read a uint256 from global engine storage
    function globalEngineUint256(string calldata key)
        external
        view
        returns (uint256);

    // Read a string from engine storage
    function engineString(uint256 tokenId, string calldata key)
        external
        returns (string memory);

    // Read a uint256 from engine storage
    function engineUint256(uint256 tokenId, string calldata key)
        external
        view
        returns (uint256);

    // Read a string from mint data
    function mintDataString(uint256 tokenId, string calldata key)
        external
        view
        returns (string memory);

    // Read a uint256 from mint data
    function mintDataUint256(uint256 tokenId, string calldata key)
        external
        view
        returns (uint256);

    // Write string data to engine storage. Only callable by engine
    function writeEngineString(
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write uint256 data to engine storage. Only callable by engine
    function writeEngineUint256(
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // Write string data to global engine storage. Only callable by engine
    function writeGlobalEngineString(string calldata key, string calldata value)
        external;

    // Write uint256 data to global engine storage. Only callable by engine
    function writeGlobalEngineUint256(string calldata key, uint256 value)
        external;

    // Mint a new token. Only callable by engine
    function mint(address to, MintOptions calldata options)
        external
        returns (uint256);
}
