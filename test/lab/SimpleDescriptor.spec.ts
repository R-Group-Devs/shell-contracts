/**
 * Should create a valid SVG
 * Should work with either ENS or SNS for reverse records
 */

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  SNS,
  SNSEngine,
  SimpleDescriptor,
  ShellERC721,
  ShellERC721__factory,
  ShellFactory
} from "../../typechain";
import { createCollection } from "./utils"

describe("SimpleDescriptor", function () {
  // ---
  // fixtures
  // ---

  let ShellERC721: ShellERC721__factory;
  let erc721: ShellERC721;
  let collection: ShellERC721;
  let factory: ShellFactory;
  let snsEngine: SNSEngine;
  let snsAddress: string;
  let simpleDescriptor: SimpleDescriptor;
  let accounts: SignerWithAddress[];
  let a0: string, a1: string, a2: string, a3: string;

  beforeEach(async () => {
    ShellERC721 = await ethers.getContractFactory("ShellERC721");
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const SNSEngine = await ethers.getContractFactory("SNSEngine");
    [erc721, factory, snsEngine, accounts] = await Promise.all([
      ShellERC721.deploy(),
      ShellFactory.deploy(),
      SNSEngine.deploy(),
      ethers.getSigners()
    ]);
    [a0, a1, a2, a3] = accounts.map((a) => a.address);
    await factory.registerImplementation("erc721", erc721.address);
    collection = await createCollection("Test", "TST", snsEngine.address, a0, factory, 4);
    await snsEngine.setPrice(collection.address, 1);
    await snsEngine.mintAndSet(collection.address, "Testo", { value: 1 });
    snsAddress = await snsEngine.getSNSAddr(collection.address);
    const SimpleDescriptor = await ethers.getContractFactory("SimpleDescriptor");
    simpleDescriptor = await SimpleDescriptor.deploy(snsAddress);
  });

  it("creates a valid SVG", async () => {
    await printURI(simpleDescriptor, collection.address, 100, a0);
  })

  it("works with ENS", async () => {
    const SimpleDescriptor = await ethers.getContractFactory("SimpleDescriptor");
    // using ENS' mainnet reverse records contract
    const simpleDescriptor = await SimpleDescriptor.deploy("0x3671aE578E63FdF66ad4F3E12CC0c0d71Ac7510C");
    await printURI(simpleDescriptor, collection.address, 100, "0x4171160dB0e7E2C75A4973b7523B437C010Dd9d4");
  })
})

async function printURI(
    sd: SimpleDescriptor, 
    collectionAddr: string, 
    tokenId: number, 
    holderAddr: string
): Promise<string> {
    const uri = await sd.getTokenURI(collectionAddr, tokenId, holderAddr);
    const [, jsonBase64] = uri.split(",");
    const json = Buffer.from(jsonBase64, "base64").toString();
    const [, imageBase64] = JSON.parse(json).image.split(",");
    const svg = Buffer.from(imageBase64, "base64").toString()
    console.log('SVG', svg);
    return svg;
}