//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IEngine.sol";
import "../IShellERC721.sol";
import "../IShellFramework.sol";
import "../engines/BeforeTokenTransferNopEngine.sol";
import "../engines/NoRoyaltiesEngine.sol";

// Simple engine with a few conventions:
contract MockEngine is IEngine, NoRoyaltiesEngine, BeforeTokenTransferNopEngine {
    string public baseUri;

    function getEngineName() external pure returns (string memory) {
        return "MockEngine";
    }

    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory ipfsHash = collection.readString(
            StorageLocation.MINT_DATA,
            tokenId,
            "ipfsHash"
        );
        return string(abi.encodePacked("ipfs://ipfs/", ipfsHash));
    }

    function writeIntToToken(
        IShellERC721 collection,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external {
        collection.writeInt(StorageLocation.ENGINE, tokenId, key, value);
    }

    function writeIntToCollection(
        IShellERC721 collection,
        string calldata key,
        uint256 value
    ) external {
        collection.writeInt(StorageLocation.ENGINE, key, value);
    }

    function mint(IShellERC721 collection, string calldata ipfsHash)
        external
        returns (uint256)
    {
        StringStorage[] memory stringData = new StringStorage[](1);
        IntStorage[] memory intData = new IntStorage[](0);

        stringData[0] = StringStorage({key: "ipfsHash", value: ipfsHash});

        uint256 tokenId = collection.mint(
            msg.sender,
            MintOptions({
                storeEngine: false,
                storeMintedTo: false,
                storeTimestamp: false,
                storeBlockNumber: false,
                stringData: stringData,
                intData: intData
            })
        );

        return tokenId;
    }

    function afterInstallEngine(IShellFramework collection)
        external
        view
        override(IEngine)
    {
        require(
            collection.supportsInterface(type(IShellERC721).interfaceId),
            "must implement IShellERC721"
        );
    }

     function afterInstallEngine(IShellFramework collection, uint256)
        external
        view
        override(IEngine)
    {
        require(
            collection.supportsInterface(type(IShellERC721).interfaceId),
            "must implement IShellERC721"
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IEngine).interfaceId;
    }
}
