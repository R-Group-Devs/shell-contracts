//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ICollection.sol";

// Required interface for framework engines
// must return true for supportsInterface(0x0cfec183)
interface IEngine is IERC165 {
    // display name for this engine
    function name() external pure returns (string memory);

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(ICollection collection, uint256 tokenId)
        external
        view
        returns (string memory);

    // Called by the collection to response a response for royaltyInfo
    function getRoyaltyInfo(
        ICollection collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // Called by the collection during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    function beforeTokenTransfer(
        ICollection collection,
        address from,
        address to,
        uint256 tokenId
    ) external;
}
