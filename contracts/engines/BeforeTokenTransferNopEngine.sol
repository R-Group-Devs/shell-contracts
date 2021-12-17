//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IEngine.sol";

abstract contract BeforeTokenTransferNopEngine is IEngine {
    function beforeTokenTransfer(
        ICollection collection,
        address,
        address,
        uint256
    ) external view {
        require(msg.sender == address(collection), "shell: invalid sender");
        return;
    }
}
