//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IPersonalizedDescriptor} from "../__lab__/squadz/IPersonalizedDescriptor.sol";

contract MockDescriptor is IPersonalizedDescriptor {

    //===== State =====//

    string public phrase;

    //===== Constructor =====//

    constructor(string memory phrase_) {
        phrase = phrase_;
    }

    //===== External Functions =====//

    function getTokenURI(address collectionAddr, uint256 tokenId, address owner) external view returns (string memory) {
        return phrase;
    }

    //===== Public Functions =====//

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IPersonalizedDescriptor).interfaceId;
    }
}