//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IEngine.sol";
import "../ICollection.sol";

// Simple engine with a few conventions:
contract MockEngine is IEngine {
    string public baseUri;

    function getTokenURI(ICollection collection, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory ipfsHash = collection.mintDataString(tokenId, "ipfsHash");
        return string(abi.encodePacked("ipfs://ipfs/", ipfsHash));
    }

    function getRoyaltyInfo(
        ICollection collection,
        uint256,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        uint256 bps = collection.globalEngineUint256("royaltyBps");
        receiver = address(
            uint160(collection.globalEngineUint256("royaltyReceiver"))
        );
        royaltyAmount = (salePrice * bps) / 10000;
    }

    function beforeTokenTransfer(
        ICollection,
        address,
        address,
        uint256
    ) external pure override {
        return; // no-op
    }

    function mint(ICollection collection, string calldata ipfsHash)
        external
        returns (uint256)
    {
        StringStorage[] memory stringData = new StringStorage[](1);
        Uint256Storage[] memory uint256Data = new Uint256Storage[](0);

        stringData[0] = StringStorage({key: "ipfsHash", value: ipfsHash});

        uint256 tokenId = collection.mint(
            msg.sender,
            MintOptions({
                storeEngine: false,
                storeMintedTo: false,
                storeMintedBy: false,
                storeTimestamp: false,
                storeBlockNumber: false,
                stringData: stringData,
                uint256Data: uint256Data
            })
        );

        return tokenId;
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
