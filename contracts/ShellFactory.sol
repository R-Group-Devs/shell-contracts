//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./libraries/Ownable.sol";
import "./IShellFactory.sol";

contract ShellFactory is IShellFactory, Ownable {
    mapping(string => IShellFramework) public implementations;

    constructor() {
        _transferOwnership(msg.sender);
    }

    function registerImplementation(
        string calldata name,
        IShellFramework implementation
    ) external onlyOwner {
        require(
            implementations[name] == IShellFramework(address(0)),
            "shell: implementation exists"
        );
        require(
            implementation.supportsInterface(type(IShellFramework).interfaceId),
            "shell: invalid implementation"
        );
        implementations[name] = implementation;
        emit ImplementationRegistered(name, implementation);
    }

    function createCollection(
        string calldata name,
        string calldata symbol,
        string calldata implementationName,
        IEngine engine,
        address owner
    ) external returns (IShellFramework) {
        IShellFramework implementation = implementations[implementationName];
        require(
            implementation != IShellFramework(address(0)),
            "shell: implementation not found"
        );
        IShellFramework clone = IShellFramework(
            Clones.clone(address(implementation))
        );
        clone.initialize(name, symbol, engine, owner);
        emit CollectionCreated(clone, implementation);
        return clone;
    }
}
