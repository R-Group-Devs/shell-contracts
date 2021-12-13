//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEngine.sol";
import "./ICollection.sol";

contract Collection is Ownable, ICollection, ERC721, IERC2981 {
    // Currently installed engine
    IEngine public engine;

    // token id serial number
    uint256 public nextTokenId = 1;

    // Owner-writeable storage, token id => key => value
    mapping(uint256 => mapping(string => string)) public ownerString;
    mapping(uint256 => mapping(string => uint256)) public ownerUint256;

    // Engine-writeable storage, token id => key => value
    mapping(uint256 => mapping(string => string)) public engineString;
    mapping(uint256 => mapping(string => uint256)) public engineUint256;

    // Only writeable during minting
    mapping(uint256 => mapping(string => string)) public mintDataString;
    mapping(uint256 => mapping(string => uint256)) public mintDataUint256;

    constructor(
        string memory name,
        string memory symbol,
        IEngine engine_,
        address owner
    ) ERC721(name, symbol) {
        _transferOwnership(owner);
        _installEngine(engine_);
    }

    modifier onlyEngine() {
        require(
            _msgSender() == address(engine),
            "caller must be installed engine"
        );
        _;
    }

    // ---
    // Collection owner (admin) functionaltiy
    // ---

    function installEngine(IEngine engine_) external override onlyOwner {
        _installEngine(engine_);
    }

    function _installEngine(IEngine engine_) internal {
        engine = engine_;
        emit EngineInstalled(engine_);
    }

    // ---
    // Owner functionality
    // ---

    function writeOwnerString(
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external override {
        require(ownerOf(tokenId) == msg.sender, "not token owner");
        ownerString[tokenId][key] = value;
        emit OwnerStringSet(tokenId, key, value);
    }

    function writeOwnerUint256(
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external override {
        require(ownerOf(tokenId) == msg.sender, "not token owner");
        ownerUint256[tokenId][key] = value;
        emit OwnerUint256Set(tokenId, key, value);
    }

    // ---
    // Engine framework
    // ---

    function writeEngineString(
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external override onlyEngine {
        engineString[tokenId][key] = value;
        emit EngineStringSet(tokenId, key, value);
    }

    function writeEngineUint256(
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external override onlyEngine {
        engineUint256[tokenId][key] = value;
        emit EngineUint256Set(tokenId, key, value);
    }

    function mint(address to, MintOptions calldata options)
        external
        override
        onlyEngine
        returns (uint256)
    {
        uint256 tokenId = nextTokenId++;
        _mint(to, tokenId);

        // write engine-provided immutable data

        for (uint256 i = 0; i < options.stringData.length; i++) {
            _writeMintDataString(
                tokenId,
                options.stringData[i].key,
                options.stringData[i].value
            );
        }

        for (uint256 i = 0; i < options.uint256Data.length; i++) {
            _writeMintDataUint256(
                tokenId,
                options.uint256Data[i].key,
                options.uint256Data[i].value
            );
        }

        // write framework provided immutable data

        if (options.storeMintedBy) {
            _writeMintDataUint256(
                tokenId,
                "$mintedBy",
                uint256(uint160(msg.sender))
            );
        }
        if (options.storeEngine) {
            _writeMintDataUint256(
                tokenId,
                "$engine",
                uint256(uint160(address(engine)))
            );
        }
        if (options.storeMintedBy) {
            _writeMintDataUint256(
                tokenId,
                "$mintedBy",
                uint256(uint160(msg.sender))
            );
        }
        if (options.storeMintedTo) {
            _writeMintDataUint256(tokenId, "$mintedTo", uint256(uint160(to)));
        }
        if (options.storeTimestamp) {
             // solhint-disable-next-line not-rely-on-time
            _writeMintDataUint256(tokenId, "$timestamp", block.timestamp);
        }
        if (options.storeBlockNumber) {
            _writeMintDataUint256(tokenId, "$blocknumber", block.number);
        }

        return tokenId;
    }

    function _writeMintDataString(
        uint256 tokenId,
        string memory key,
        string memory value
    ) internal {
        require(bytes(key)[0] != "$", "invalid key");
        mintDataString[tokenId][key] = value;
        emit MintDataStringSet(tokenId, key, value);
    }

    function _writeMintDataUint256(
        uint256 tokenId,
        string memory key,
        uint256 value
    ) internal {
        require(bytes(key)[0] != "$", "invalid key");
        mintDataUint256[tokenId][key] = value;
        emit MintDataUint256Set(tokenId, key, value);
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
        return engine.getTokenURI(this, tokenId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return engine.getRoyaltyInfo(this, tokenId, salePrice);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        try engine.beforeTokenTransfer(this, from, to, tokenId) {
            return;
        } catch {
            // engine reverted, but we don't want to block the transfer
            return;
        }
    }
}
