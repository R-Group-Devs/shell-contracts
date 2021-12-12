//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC2981.sol";
import "./IEngine.sol";

struct StringStorage {
    string key;
    string value;
}

struct Uint256Storage {
    string key;
    uint256 value;
}

contract Collection is Ownable, ERC721, IERC2981 {
    IEngine public engine;

    // emitted whenever a new engine is installed
    event EngineInstalled(IEngine indexed engine);

    // token owner has updated a stored string
    event OwnerStringSet(
        uint256 indexed tokenId,
        string indexed key,
        string indexed value
    );

    // engine has updated a stored string
    event EngineStringSet(
        uint256 indexed tokenId,
        string indexed key,
        string indexed value
    );

    // token owner has updated a stored uint256
    event OwnerUint256Set(
        uint256 indexed tokenId,
        string indexed key,
        uint256 indexed value
    );

    // engine has updated a stored uint256
    event EngineUint256Set(
        uint256 indexed tokenId,
        string indexed key,
        uint256 indexed value
    );

    // an emit proxied from the installed engine
    event EngineBroadcast(
        string indexed topic,
        uint256 indexed aParam,
        uint256 indexed bParam,
        string data
    );

    // token id serial number
    uint256 public nextTokenId = 1;

    // owner-writeable storage, token id => key => value
    mapping(uint256 => mapping(string => string)) public ownerString;
    mapping(uint256 => mapping(string => uint256)) public ownerUint256;

    // engine-writeable storage, token id => key => value
    mapping(uint256 => mapping(string => string)) public engineString;
    mapping(uint256 => mapping(string => uint256)) public engineUint256;

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

    function writeOwnerString(
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external {
        require(ownerOf(tokenId) == msg.sender, "not token owner");
        ownerString[tokenId][key] = value;
        emit OwnerStringSet(tokenId, key, value);
    }

    function writeEngineString(
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external onlyEngine {
        engineString[tokenId][key] = value;
        emit EngineStringSet(tokenId, key, value);
    }

    function writeOwnerUint256(
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external {
        require(ownerOf(tokenId) == msg.sender, "not token owner");
        ownerUint256[tokenId][key] = value;
        emit OwnerUint256Set(tokenId, key, value);
    }

    function writeEngineString(
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external onlyEngine {
        engineUint256[tokenId][key] = value;
        emit EngineUint256Set(tokenId, key, value);
    }

    // swap out the current engine. Can only be called by owner
    function installEngine(IEngine engine_) external onlyOwner {
        _installEngine(engine_);
    }

    // delegate resolution of tokenURI to currently installed engine
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return engine.getTokenURI(this, tokenId);
    }

    // mint a new token. Can only be called by the currently installed engine
    function mint(address to) external onlyEngine returns (uint256) {
        uint256 tokenId = nextTokenId++;
        _mint(to, tokenId);
        return tokenId;
    }

    // Broadcast an event. Can only be called by the currently installed engine
    function broadcast(
        string calldata topic,
        uint256 a,
        uint256 b,
        string calldata data
    ) external onlyEngine {
        emit EngineBroadcast(topic, a, b, data);
    }

    // delegate resolution of royaltyInfo to the currently installed engine
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return engine.getRoyaltyInfo(this, tokenId, salePrice);
    }

    // open zep hook, will be called on all transfers (including mint and burn).
    // Delegates to the currently installed engine, but does not allow breaking
    // token transfer
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

    function _installEngine(IEngine engine_) internal {
        engine = engine_;
        emit EngineInstalled(engine_);
    }
}
