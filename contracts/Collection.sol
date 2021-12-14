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
    IEngine public engine;

    // token id serial number
    uint256 public nextTokenId;

    // Owner-writeable storage, token id => key => value
    mapping(uint256 => mapping(string => string)) public override ownerString;
    mapping(uint256 => mapping(string => uint256)) public override ownerUint256;

    // Engine-writeable storage, token id => key => value
    mapping(uint256 => mapping(string => string)) public override engineString;
    mapping(uint256 => mapping(string => uint256))
        public
        override engineUint256;

    // Only writeable during minting
    mapping(uint256 => mapping(string => string))
        public
        override mintDataString;
    mapping(uint256 => mapping(string => uint256))
        public
        override mintDataUint256;

    function initialize(
        string calldata name,
        string calldata symbol,
        IEngine engine_,
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
        _installEngine(engine_);
        nextTokenId = 1;
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
        require(
            engine_.supportsInterface(type(IEngine).interfaceId),
            "IEngine not supported"
        );
        engine = engine_;
        emit EngineInstalled(engine_);
    }

    // ---
    // NFT Owner functionality
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

    function globalEngineString(string calldata key)
        external
        view
        override
        returns (string memory)
    {
        return engineString[0][key];
    }

    function globalEngineUint256(string calldata key)
        external
        view
        override
        returns (uint256)
    {
        return engineUint256[0][key];
    }

    function writeGlobalEngineString(string calldata key, string calldata value)
        external
        override
        onlyEngine
    {
        engineString[0][key] = value;
    }

    function writeGlobalEngineUint256(string calldata key, uint256 value)
        external
        override
        onlyEngine
    {
        engineUint256[0][key] = value;
    }

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
            require(bytes(options.stringData[i].key)[0] != "$", "invalid key");
            _writeMintDataString(
                tokenId,
                options.stringData[i].key,
                options.stringData[i].value
            );
        }

        for (uint256 i = 0; i < options.uint256Data.length; i++) {
            require(bytes(options.uint256Data[i].key)[0] != "$", "invalid key");
            _writeMintDataUint256(
                tokenId,
                options.uint256Data[i].key,
                options.uint256Data[i].value
            );
        }

        // write framework provided immutable data

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
        mintDataString[tokenId][key] = value;
        emit MintDataStringSet(tokenId, key, value);
    }

    function _writeMintDataUint256(
        uint256 tokenId,
        string memory key,
        uint256 value
    ) internal {
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
        try engine.beforeTokenTransfer(this, from, to, tokenId) {
            return;
        } catch {
            // engine reverted, but we don't want to block the transfer
            return;
        }
    }
}
