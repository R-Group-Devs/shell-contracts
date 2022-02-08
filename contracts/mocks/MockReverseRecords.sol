//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IReverseRecords} from "../__lab__/Memberships/MembershipsEngine.sol";

contract MockReverseRecords is IReverseRecords {
    function getNames(address[] calldata addresses)
        external
        pure
        returns (string[] memory r)
    {
        r = new string[](addresses.length);
        for (uint256 i; i < r.length; i++) {
            r[i] = "NAME";
        }
    }
}
