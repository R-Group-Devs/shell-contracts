//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IEngine.sol";
import {IShellFramework, StorageLocation} from "../IShellFramework.sol";

abstract contract SimpleRoyaltiesEngine is IEngine {
    //===== External Functions =====//

    function getRoyaltyInfo(
        IShellFramework collection,
        uint256,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = address(uint160(
            collection.readCollectionInt(StorageLocation.ENGINE, _royaltyReceiverKey(collection))
        ));
        uint256 basisPoints = collection.readCollectionInt(StorageLocation.ENGINE, _royaltyBasisKey(collection));
        royaltyAmount = salePrice * basisPoints / 10000;
    }

    //===== Public Functions =====//

    function setRoyaltyInfo(
        IShellFramework collection,
        address receiver,
        uint256 royaltyBasisPoints
    ) public {
        require(msg.sender == collection.owner(), "SNS: msg.sender not collection owner");
        collection.writeCollectionInt(
            StorageLocation.ENGINE,
            _royaltyReceiverKey(collection),
            uint256(uint160(receiver))
        );
        collection.writeCollectionInt(StorageLocation.ENGINE, _royaltyBasisKey(collection), royaltyBasisPoints);
    }

    //===== Private Functions =====//

    function _royaltyReceiverKey(IShellFramework collection) private pure returns (string memory) {
        return string(abi.encodePacked(address(collection), "ROYALTY_RECEIVER"));
    }

    function _royaltyBasisKey(IShellFramework collection) private pure returns (string memory) {
        return string(abi.encodePacked(address(collection), "ROYALTY_BASIS"));
    }
}
