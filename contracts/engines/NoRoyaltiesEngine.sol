//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IShellFramework.sol";

abstract contract NoRoyaltiesEngine is IEngine {
    function getRoyaltyInfo(
        IShellFramework,
        uint256,
        uint256
    ) external pure returns (address receiver, uint256 royaltyAmount) {
        receiver = address(0);
        royaltyAmount = 0;
    }
}
