#!/bin/bash

yarn build
cp ./artifacts/contracts/IEngine.sol/IEngine.json ../shell-subgraph/abis/
cp ./artifacts/contracts/IShellFramework.sol/IShellFramework.json ../shell-subgraph/abis/
cp ./artifacts/contracts/ShellFactory.sol/ShellFactory.json ../shell-subgraph/abis/
