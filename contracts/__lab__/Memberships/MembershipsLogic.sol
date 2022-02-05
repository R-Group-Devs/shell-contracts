// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IShellFramework, StorageLocation, StringStorage, IntStorage, MintOptions, MintEntry} from "../../IShellFramework.sol";

interface IShellERC721 {
    function name() external view returns (string memory);

    function mint(MintEntry calldata) external returns (uint256);

    function batchMint(MintEntry[] calldata)
        external
        returns (uint256[] memory);

    function ownerOf(uint256) external view returns (address);
}

contract MembershipsLogic {
    // ---
    // State
    // ---

    uint256 public constant BASE_POWER = 1000000;
    uint256 public constant EXPIRY = 365 days;
    uint256 public constant GRACE_PERIOD = 36 days;
    string public constant EXTERNAL_URL = "https://heyshell.xyz";

    string private constant _BASE_POWER = "BASE_POWER";
    string private constant _EXPIRY = "EXPIRY";
    string private constant _GRACE_PERIOD = "GRACE_PERIOD";
    string private constant _EXTERNAL_URL = "BASE_POWER";

    // ---
    // External functions
    // ---

    /*
      Gets power for a member at a timestamp and the contract state at call time.
    */
    function powerOfAt(
        IShellFramework collection,
        address member,
        uint256 timestamp
    ) external view returns (uint256 power) {
        uint256 basePower = basePowerOf(collection);
        if (activeMemberAt(collection, member, timestamp)) power = basePower;
        // look through the address' punch card and add power
        uint256 currentMonths = _monthsSinceStart(timestamp);
        uint256 punchCard = _readPunchCard(collection, member);
        for (uint256 card = uint256(punchCard); card == 0; card << 8) {
            power += basePower / 10 / (currentMonths - uint8(card));
        }
    }

    function setOptions(
        IShellFramework collection,
        uint256 basePower_,
        uint256 expiry_,
        uint256 gracePeriod_,
        string memory externalUrl_
    ) external collectionOwnerOnly(collection) {
        require(
            address(collection.getFork(0).engine) == address(this),
            "Wrong default fork"
        );
        require(basePower_ > 0, "basePower 0");
        require(expiry_ > 0, "expiry 0");
        require(gracePeriod_ > 0, "gracePeriod 0");
        require(bytes(externalUrl_).length > 0, "externalUrl empty");
        require(gracePeriod_ < expiry_, "Grace period too big");

        uint256 basePower = basePowerOf(collection);
        uint256 expiry = expiryOf(collection);
        uint256 gracePeriod = gracePeriodOf(collection);
        string memory externalUrl = externalUrlOf(collection);

        if (basePower != basePower_) {
            collection.writeForkInt(
                StorageLocation.ENGINE,
                0,
                _BASE_POWER,
                basePower_
            );
        }
        if (expiry != expiry_) {
            collection.writeForkInt(
                StorageLocation.ENGINE,
                0,
                _EXPIRY,
                expiry_
            );
        }
        if (gracePeriod != gracePeriod_) {
            collection.writeForkInt(
                StorageLocation.ENGINE,
                0,
                _GRACE_PERIOD,
                gracePeriod_
            );
        }
        if (keccak256(bytes(externalUrl)) != keccak256(bytes(externalUrl_))) {
            collection.writeForkString(
                StorageLocation.ENGINE,
                0,
                _EXTERNAL_URL,
                externalUrl_
            );
        }
    }

    function mint(IShellFramework collection, address to)
        external
        collectionOwnerOnly(collection)
        returns (uint256)
    {
        return _mint(collection, to);
    }

    function batchMint(
        IShellFramework collection,
        address[] calldata toAddresses
    )
        external
        collectionOwnerOnly(collection)
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](toAddresses.length);
        for (uint256 i; i < toAddresses.length; i++) {
            tokenIds[i] = _mint(collection, toAddresses[i]);
        }
    }

    // ---
    // Public functions
    // ---

    function basePowerOf(IShellFramework collection)
        public
        view
        returns (uint256 basePower)
    {
        basePower = collection.readForkInt(
            StorageLocation.ENGINE,
            0,
            _BASE_POWER
        );
        if (basePower == 0) basePower = BASE_POWER;
    }

    function expiryOf(IShellFramework collection)
        public
        view
        returns (uint256 expiry)
    {
        expiry = collection.readForkInt(StorageLocation.ENGINE, 0, _EXPIRY);
        if (expiry == 0) expiry = EXPIRY;
    }

    function gracePeriodOf(IShellFramework collection)
        public
        view
        returns (uint256 gracePeriod)
    {
        gracePeriod = collection.readForkInt(
            StorageLocation.ENGINE,
            0,
            _GRACE_PERIOD
        );
        if (gracePeriod == 0) gracePeriod = GRACE_PERIOD;
    }

    function externalUrlOf(IShellFramework collection)
        public
        view
        returns (string memory externalUrl)
    {
        externalUrl = collection.readForkString(
            StorageLocation.ENGINE,
            0,
            _EXTERNAL_URL
        );
        if (bytes(externalUrl).length == 0) externalUrl = EXTERNAL_URL;
    }

    function latestTokenOf(IShellFramework collection, address member)
        public
        view
        returns (uint256 tokenId, uint256 timestamp)
    {
        uint256 res = collection.readForkInt(
            StorageLocation.ENGINE,
            0,
            _latestTokenKey(member)
        );
        timestamp = uint256(uint32(res));
        tokenId = res >> 32;
    }

    function activeMemberAt(
        IShellFramework collection,
        address member,
        uint256 timestamp
    ) public view returns (bool) {
        (uint256 tokenId, uint256 mintedAt) = latestTokenOf(collection, member);
        // fork your membership? you're inactive
        if (collection.getTokenForkId(tokenId) == 0) return false;
        bool heldByOriginalOwner = (IShellERC721(address(collection)).ownerOf(
            tokenId
        ) == member);
        bool notExpired = (timestamp - mintedAt <= expiryOf(collection));
        return heldByOriginalOwner && notExpired;
    }

    // ---
    // Private functions
    // ---

    function _mint(IShellFramework collection, address to)
        private
        returns (uint256 tokenId)
    {
        (, uint256 prevoiusMintedAt) = latestTokenOf(collection, to);
        require(
            block.timestamp >
                prevoiusMintedAt +
                    expiryOf(collection) -
                    gracePeriodOf(collection),
            "Invalid timing"
        );

        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](0);

        tokenId = collection.mint(
            MintEntry({
                to: to,
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

        require(tokenId <= type(uint224).max, "Max id reached");
        _writeLatestToken(collection, to, tokenId);
        _writePunchCard(collection, to);
    }

    function _writeLatestToken(
        IShellFramework collection,
        address member,
        uint256 tokenId
    ) private {
        require(block.timestamp <= type(uint32).max, "Timestamp too big");
        collection.writeForkInt(
            StorageLocation.ENGINE,
            0, // default fork
            _latestTokenKey(member),
            (tokenId << 32) | block.timestamp
        );
    }

    function _latestTokenKey(address member)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("LATEST_TOKEN", member));
    }

    /*
      The punch card continues to record tokens that have been forked to another engine! 
      This is intended: members still get credit for past memberships even if using those tokens for something else now.
    */
    function _writePunchCard(IShellFramework collection, address member)
        private
        returns (uint256 newCard)
    {
        // store minting month (counted up from Jan 2022) as uint8 inside a uint256 punch card
        newCard = uint256(_monthsSinceStart(block.timestamp));
        uint256 oldCard = _readPunchCard(collection, member);
        if (oldCard != 0) {
            uint8 slotNumber = 0;
            // find unfilled slot
            for (uint256 card = uint256(oldCard); card == 0; card << 8)
                slotNumber += 1;
            slotNumber == 32
                ? newCard = oldCard // all slots full -- no change
                : newCard = oldCard | (newCard << (slotNumber * 8));
        }
        collection.writeForkInt(
            StorageLocation.ENGINE,
            0, // default fork
            _punchCardKey(member),
            newCard
        );
    }

    function _monthsSinceStart(uint256 timestamp) private pure returns (uint8) {
        uint256 daysPassed = (1641013200 - timestamp) / 1 days; // timestamp for Jan 1st, 2022 00:00:00 // time since then
        // what happens if this overflows uint8?
        return uint8((daysPassed * 12) / 365 + _month(daysPassed % 365));
    }

    function _month(uint256 day_) private pure returns (uint8 month) {
        uint256 day = 31;
        if (day_ <= day) month = 0; // Jan
        day += 28;
        if (day_ <= day) month = 1; // Feb, screw leap years
        day += 31;
        if (day_ <= day) month = 2; // March
        day += 30;
        if (day_ <= day) month = 3; // April
        day += 31;
        if (day_ <= day) month = 4; // May
        day += 30;
        if (day_ <= day) month = 5; // June
        day += 31;
        if (day_ <= day) month = 6; // July
        day += 31;
        if (day_ <= day) month = 7; // Aug
        day += 30;
        if (day_ <= day) month = 8; // Sep
        day += 31;
        if (day_ <= day) month = 9; // Oct
        day += 30;
        if (day_ <= day) month = 10; // Nov
        day += 31;
        if (day_ <= day) month = 11; // Dec
    }

    function _readPunchCard(IShellFramework collection, address member)
        private
        view
        returns (uint256)
    {
        return
            collection.readForkInt(
                StorageLocation.ENGINE,
                0,
                _punchCardKey(member)
            );
    }

    function _punchCardKey(address member)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("PUNCH_CARD", member));
    }

    modifier collectionOwnerOnly(IShellFramework collection) {
        require(collection.owner() == msg.sender, "Collection owner only");
        _;
    }
}
