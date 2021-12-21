//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./ShellERC721.sol";

contract ShellFactory {
    ShellERC721 public immutable implementation;

    event CollectionCreated(
        IShellFramework collection,
        string name,
        string symbol,
        IEngine engine,
        address owner
    );

    constructor() {
        implementation = new ShellERC721();
    }

    // deploy a new (cloned) colllection
    function createCollection(
        string calldata name,
        string calldata symbol,
        IEngine engine,
        address owner
    ) external returns (IShellFramework) {
        ShellERC721 clone = ShellERC721(Clones.clone(address(implementation)));
        clone.initialize(name, symbol, engine, owner);
        emit CollectionCreated(clone, name, symbol, engine, owner);
        return clone;
    }
}
