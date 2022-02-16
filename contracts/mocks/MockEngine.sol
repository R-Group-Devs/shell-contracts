//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../engines/ShellBaseEngine.sol";

// Simple engine with a few conventions:
contract MockEngine is ShellBaseEngine {
    function name() external pure override returns (string memory) {
        return "mock-engine";
    }

    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory ipfsHash = collection.readTokenString(
            StorageLocation.MINT_DATA,
            tokenId,
            "ipfsHash"
        );
        return string(abi.encodePacked("ipfs://ipfs/", ipfsHash));
    }

    // 10% on everything
    function getRoyaltyInfo(
        IShellFramework collection,
        uint256,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = collection.owner();
        royaltyAmount = (salePrice * 1000) / 10000;
    }

    // pass thru write
    function writeIntToToken(
        IShellFramework collection,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external {
        collection.writeTokenInt(StorageLocation.ENGINE, tokenId, key, value);
    }

    // pass thru write
    function writeIntToFork(
        IShellFramework collection,
        uint256 forkId,
        string calldata key,
        uint256 value
    ) external {
        collection.writeForkInt(StorageLocation.ENGINE, forkId, key, value);
    }

    // pass thru write
    function writeStringToToken(
        IShellFramework collection,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external {
        collection.writeTokenString(
            StorageLocation.ENGINE,
            tokenId,
            key,
            value
        );
    }

    // pass thru write
    function writeStringToFork(
        IShellFramework collection,
        uint256 forkId,
        string calldata key,
        string calldata value
    ) external {
        collection.writeForkString(StorageLocation.ENGINE, forkId, key, value);
    }

    function invalidForkWrite(IShellFramework collection, uint256 forkId)
        external
    {
        collection.writeForkString(
            StorageLocation.MINT_DATA,
            forkId,
            "foo",
            "bar"
        );
    }

    function invalidTokenWrite(IShellFramework collection, uint256 tokenId)
        external
    {
        collection.writeTokenString(
            StorageLocation.MINT_DATA,
            tokenId,
            "foo",
            "bar"
        );
    }

    // mint pass thru
    function mintPassthrough(
        IShellFramework collection,
        MintEntry calldata entry
    ) external returns (uint256) {
        return collection.mint(entry);
    }

    // store ipfs in mint data
    function mint(IShellFramework collection, string calldata ipfsHash)
        external
        returns (uint256)
    {
        StringStorage[] memory stringData = new StringStorage[](1);
        IntStorage[] memory intData = new IntStorage[](0);

        stringData[0] = StringStorage({key: "ipfsHash", value: ipfsHash});

        uint256 tokenId = collection.mint(
            MintEntry({
                to: msg.sender,
                amount: 1,
                options: MintOptions({
                    storeEngine: false,
                    storeMintedTo: false,
                    storeTimestamp: false,
                    storeBlockNumber: false,
                    stringData: stringData,
                    intData: intData
                })
            })
        );

        return tokenId;
    }
}
