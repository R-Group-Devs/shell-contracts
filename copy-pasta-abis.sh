#!/bin/bash

yarn build
cp ./artifacts/contracts/IEngine.sol/IEngine.json ../shell-subgraph/abis/
cp ./artifacts/contracts/IShellFramework.sol/IShellFramework.json ../shell-subgraph/abis/
cp ./artifacts/contracts/IShellERC721.sol/IShellERC721.json ../shell-subgraph/abis/
cp ./artifacts/contracts/ShellFactory.sol/ShellFactory.json ../shell-subgraph/abis/

cp ./artifacts/contracts/IEngine.sol/IEngine.json ../shell-frontend/src/shell/abis
cp ./artifacts/contracts/ShellFactory.sol/ShellFactory.json ../shell-frontend/src/shell/abis/
