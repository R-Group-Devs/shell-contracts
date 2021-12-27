#!/bin/bash

# script to copy ABIs from this repo to sibling repos (subgraph and frontend)

BASE=./artifacts/contracts
GRAPH=../shell-subgraph/abis/
FRONTEND=../shell-frontend/src/shell/abis/

yarn build \
  && cp \
    $BASE/IEngine.sol/IEngine.json \
    $BASE/IShellFramework.sol/IShellFramework.json \
    $BASE/IShellERC721.sol/IShellERC721.json \
    $BASE/IShellERC1155.sol/IShellERC1155.json \
    $BASE/IShellFactory.sol/IShellFactory.json \
      $GRAPH \
  && cp \
    $BASE/IEngine.sol/IEngine.json \
    $BASE/IShellFramework.sol/IShellFramework.json \
    $BASE/IShellFactory.sol/IShellFactory.json \
      $FRONTEND
