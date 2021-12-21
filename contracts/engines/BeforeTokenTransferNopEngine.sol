//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IEngine.sol";
import "../IShellFramework.sol";

abstract contract BeforeTokenTransferNopEngine is IEngine {
    function beforeTokenTransfer(
        IShellFramework collection,
        address,
        address,
        address,
        uint256[] memory,
        uint256[] memory
    ) external view override {
        require(msg.sender == address(collection), "shell: invalid sender");
        return;
    }
}
