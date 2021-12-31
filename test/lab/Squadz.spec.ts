/**
 * Squadz Engine
 * 
 * mint
 * - only callable by collection admins or owner
 * - mints an admin or non-admin token to an address
 * 
 * batchMint
 * - only callable by collection admins or owner
 * - fails if array lengths are different
 * - mints admin or non-admin tokens to each address
 * 
 * constructor
 * - address must support correct interface
 * 
 * afterInstallEngine
 * - only permits collections that fit correct interfaces
 * 
 * getTokenURI
 * - returns a string
 * - uses the adminDescriptor for admin tokens
 * - uses the non-admin descriptor for member tokens
 * - uses the default descriptor if no descriptor is set
 * 
 * beforeTokenTransfer
 * - can only be called by collection
 * - when transfering an admin token, changes admin token counts correctly
 * - when transfering a non-admin token, does not change admin token count
 * 
 * setDescriptor
 * - sets specified descriptor
 * - fails in descriptor interface not supported
 * 
 * mintedTo
 * - retrieves correct mintedTo address
 * 
 * isAdminToken
 * - returns true for admin tokens, false otherwise
 * 
 * isAdmin
 * - returns true for holders of admin tokens, false otherwise
 * 
 */

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect, assert } from "chai";
import { ethers } from "hardhat";
import {
  SNS,
  SNSEngine,
  SimpleDescriptor,
  MockDescriptor,
  SquadzEngine,
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
  let snsCollection: ShellERC721;
  let squadzCollection: ShellERC721;
  let factory: ShellFactory;
  let snsEngine: SNSEngine;
  let squadzEngine: SquadzEngine;
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

    snsCollection = await createCollection("Simple Names", "SNS", snsEngine.address, a0, factory, 4);
    await snsEngine.setPrice(snsCollection.address, 1);
    await snsEngine.mintAndSet(snsCollection.address, "Testo", { value: 1 });
    snsAddress = await snsEngine.getSNSAddr(snsCollection.address);
    const SimpleDescriptor = await ethers.getContractFactory("SimpleDescriptor");
    simpleDescriptor = await SimpleDescriptor.deploy(snsAddress);

    const SquadzEngine = await ethers.getContractFactory("SquadzEngine");
    squadzEngine = await SquadzEngine.deploy(simpleDescriptor.address);

    const defaultDesc = await squadzEngine.defaultDescriptor();
    assert.equal(defaultDesc, simpleDescriptor.address, "descriptor address");

    squadzCollection = await createCollection("Test Squadz", "TSQD", squadzEngine.address, a0, factory, 2);
  });

  describe("mint", function () {
    it("owner mints an admin token", async () => {
      await mintAndCheck(squadzCollection, squadzEngine, a0, true);
    });

    it("owner mints a non-admin token", async () => {
      await mintAndCheck(squadzCollection, squadzEngine, a1, false);
    });

    it("admin mints an admin token", async () => {
      await mintAndCheck(squadzCollection, squadzEngine, a1, true);
      const a1engine = squadzEngine.connect(accounts[1]);
      await mintAndCheck(squadzCollection, a1engine, a2, true);
    });

    it("admin mints a non-admin token", async () => {
      await mintAndCheck(squadzCollection, squadzEngine, a1, true);
      const a1engine = squadzEngine.connect(accounts[1]);
      await mintAndCheck(squadzCollection, a1engine, a2, false);
    });

    it("prevents non-admin, non-owner minting", async () => {
      const a1engine = squadzEngine.connect(accounts[1]);
      await expect(a1engine.mint(squadzCollection.address, a2, true))
        .to.be.revertedWith("SQUADZ: only collection owner or admin token holder can mint");
      await expect(a1engine.mint(squadzCollection.address, a2, false))
        .to.be.revertedWith("SQUADZ: only collection owner or admin token holder can mint");
    });
  });

  describe("batchMint", function () {
    it("owner mints admin or non-admin tokens to each address", async () => {
        await batchMintAndCheck(
          squadzCollection,
          squadzEngine,
          [a1, a2, a3],
          [false, true, false]
        );
    });

    it("admin mints admin or non-admin tokens to each address", async () => {
      await mintAndCheck(squadzCollection, squadzEngine, a1, true);
      const a1engine = squadzEngine.connect(accounts[1]);
      await batchMintAndCheck(
        squadzCollection,
        a1engine,
        [a2, a3],
        [false, true]
      );
    });

    it("fails if array lengths are different", async () => {
      await expect(squadzEngine.batchMint(squadzCollection.address, [a1, a2], [true]))
        .to.be.revertedWith("SQUADZ: toAddresses and adminBools arrays have different lengths");
    });

    it("prevents non-admin, non-owner minting", async () => {
      const a1engine = squadzEngine.connect(accounts[1]);
      await expect(a1engine.batchMint(squadzCollection.address, [a2, a3], [true, false]))
        .to.be.revertedWith("SQUADZ: only collection owner or admin token holder can mint");
    });
  });

  describe("getTokenURI", function () {
    it("uses the default descriptor if no descriptor is set", async () => {
      const adminDesc = await squadzEngine.getDescriptor(squadzCollection.address, true);
      assert.equal(adminDesc, ethers.constants.AddressZero, "adminDesc");
      const memberDesc = await squadzEngine.getDescriptor(squadzCollection.address, true);
      assert.equal(memberDesc, ethers.constants.AddressZero, "memberDesc");

      await mintAndCheck(squadzCollection, squadzEngine, a0, true);

      const uri1 = await squadzCollection.tokenURI(1);
      const uri2 = await simpleDescriptor.getTokenURI(squadzCollection.address, 1, a0);
      assert.equal(uri1, uri2, "uri");
    });

    it("uses the adminDescriptor for admin tokens", async () => {
      const adminDescBefore = await squadzEngine.getDescriptor(squadzCollection.address, true);
      assert.equal(adminDescBefore, ethers.constants.AddressZero, "adminDescBefore");

      const MockDescriptor = await ethers.getContractFactory("MockDescriptor");
      const mockDescriptor = await MockDescriptor.deploy("admin");
      await squadzEngine.setDescriptor(squadzCollection.address, mockDescriptor.address, true);
      const adminDescAfter = await squadzEngine.getDescriptor(squadzCollection.address, true);
      assert.equal(adminDescAfter, mockDescriptor.address, "adminDescAfter");

      await mintAndCheck(squadzCollection, squadzEngine, a0, true);
      const uri1 = await squadzCollection.tokenURI(1);
      const uri2 = await mockDescriptor.getTokenURI(squadzCollection.address, 1, a0);
      assert.equal(uri1, uri2, "uri")
    });

    it("uses the non-descriptor for non-admin tokens", async () => {
      const adminDescBefore = await squadzEngine.getDescriptor(squadzCollection.address, false);
      assert.equal(adminDescBefore, ethers.constants.AddressZero, "adminDescBefore");

      const MockDescriptor = await ethers.getContractFactory("MockDescriptor");
      const mockDescriptor = await MockDescriptor.deploy("member");
      await squadzEngine.setDescriptor(squadzCollection.address, mockDescriptor.address, false);
      const adminDescAfter = await squadzEngine.getDescriptor(squadzCollection.address, false);
      assert.equal(adminDescAfter, mockDescriptor.address, "adminDescAfter");

      await mintAndCheck(squadzCollection, squadzEngine, a0, false);
      const uri1 = await squadzCollection.tokenURI(1);
      const uri2 = await mockDescriptor.getTokenURI(squadzCollection.address, 1, a0);
      assert.equal(uri1, uri2, "uri")
    });
    
  });

});

async function mintAndCheck(
  squadzCollection: ShellERC721,
  squadzEngine: SquadzEngine,
  to: string,
  adminBool: boolean
) {
  const beforeBalance = await squadzCollection.balanceOf(to);
  let nextTokenId = await squadzCollection.nextTokenId();

  await expect(squadzEngine.mint(squadzCollection.address, to, adminBool))
    .to.emit(squadzCollection, "Transfer")
    .withArgs(
      ethers.constants.AddressZero,
      to,
      nextTokenId
    );

  const afterBalance = await squadzCollection.balanceOf(to);
  const isAdmin = await squadzEngine.isAdmin(squadzCollection.address, to);
  nextTokenId = await squadzCollection.nextTokenId();
  const isAdminToken = await squadzEngine.isAdminToken(squadzCollection.address, nextTokenId.sub(1));

  assert.deepEqual(beforeBalance.add(1), afterBalance, "balance");
  assert.equal(isAdmin, adminBool, "isAdmin");
  assert.equal(isAdminToken, adminBool, "isAdminToken");
}

async function batchMintAndCheck(
  squadzCollection: ShellERC721,
  squadzEngine: SquadzEngine,
  toAddrs: string[],
  adminBools: boolean[]
) {
  const beforeBalances = [];
  for (let i = 0; i < toAddrs.length; i++) beforeBalances.push(await squadzCollection.balanceOf(toAddrs[i]));
  let nextTokenId = await squadzCollection.nextTokenId();

  await expect(squadzEngine.batchMint(squadzCollection.address, toAddrs, adminBools))
    .to.emit(squadzCollection, "Transfer");

  for (let i = 0; i < toAddrs.length; i++) {
    const to = toAddrs[i];
    const beforeBalance = beforeBalances[i];
    const adminBool = adminBools[i];
    const afterBalance = await squadzCollection.balanceOf(to);
    const isAdmin = await squadzEngine.isAdmin(squadzCollection.address, to);
    const isAdminToken = await squadzEngine.isAdminToken(squadzCollection.address, nextTokenId.add(i));

    assert.deepEqual(beforeBalance.add(1), afterBalance, "balance");
    assert.equal(isAdmin, adminBool, "isAdmin");
    assert.equal(isAdminToken, adminBool, "isAdminToken");
  }
}