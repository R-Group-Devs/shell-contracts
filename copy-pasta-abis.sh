#!/bin/bash

# script to copy ABIs from this repo to sibling repos (subgraph and frontend)

BASE=./artifacts/contracts
OZ_BASE=./artifacts/@openzeppelin/contracts-upgradeable
GRAPH=../shell-subgraph/abis
FRONTEND=../shell-frontend/src/shell/abis

yarn build \
  && cp \
    $BASE/IEngine.sol/IEngine.json \
    $BASE/IShellFramework.sol/IShellFramework.json \
    $BASE/IShellFactory.sol/IShellFactory.json \
    $OZ_BASE/token/ERC721/IERC721Upgradeable.sol/IERC721Upgradeable.json \
    $OZ_BASE/token/ERC1155/IERC1155Upgradeable.sol/IERC1155Upgradeable.json \
      $GRAPH \
  && cp \
    $BASE/IEngine.sol/IEngine.json \
    $BASE/IShellFramework.sol/IShellFramework.json \
    $BASE/IShellFactory.sol/IShellFactory.json \
      $FRONTEND
