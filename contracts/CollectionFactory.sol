//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Collection.sol";

contract CollectionFactory {
    Collection public immutable implementation;

    event CollectionCreated(
        Collection indexed collection,
        string name,
        string symbol,
        IEngine engine,
        address owner
    );

    constructor() {
        implementation = new Collection();
    }

    // deploy a new (cloned) colllection
    function createCollection(
        string calldata name,
        string calldata symbol,
        IEngine engine,
        address owner
    ) external returns (Collection) {
        Collection clone = Collection(Clones.clone(address(implementation)));
        clone.initialize(name, symbol, engine, owner);
        emit CollectionCreated(clone, name, symbol, engine, owner);
        return clone;
    }
}
