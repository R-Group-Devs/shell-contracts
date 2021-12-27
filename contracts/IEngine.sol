//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IShellFramework.sol";

// Required interface for framework engines
// interfaceId = 0x805590d2
interface IEngine is IERC165 {
    // Get the name for this engine
    function getEngineName() external pure returns (string memory);

    // Called by the framework to resolve a response for tokenURI method
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory);

    // Called by the framework to resolve a response for royaltyInfo method
    function getRoyaltyInfo(
        IShellFramework collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // Called by the framework during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    //
    // The engine MUST assert msg.sender == collection address!!
    //
    function beforeTokenTransfer(
        IShellFramework collection,
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    // Called by the framework following an engine install to a collection. Can
    // be used by the engine to block (by reverting) installation if needed.
    //
    // The engine MUST assert msg.sender == collection address!!
    //
    function afterInstallEngine(IShellFramework collection) external;

    // Called by the framework following an engine install to specific token.
    // Can be used by the engine to block (by reverting) installation if needed.
    //
    // The engine MUST assert msg.sender == collection address!!
    //
    function afterInstallEngine(IShellFramework collection, uint256 tokenId) external;
}
