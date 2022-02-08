import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { AddressZero } from "@ethersproject/constants"
import { expect, assert } from "chai";
import { ethers } from "hardhat";
import {
  ShellFactory,
  ShellERC721,
  ShellERC721__factory,
  MockReverseRecords,
  MembershipsEngine,
} from "../typechain";

describe("ShellFactory", function () {
  // ---
  // fixtures
  // ---

  let ShellERC721: ShellERC721__factory;
  let erc721: ShellERC721;
  let factory: ShellFactory;
  let accounts: SignerWithAddress[];
  let mockReverseRecords: MockReverseRecords;
  let testEngine: MembershipsEngine;
  let collection: ShellERC721;
  let a0: string, a1: string, a2: string, a3: string;

  beforeEach(async () => {
    ShellERC721 = await ethers.getContractFactory("ShellERC721");
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const MockReverseRecords = await ethers.getContractFactory("MockReverseRecords");
    const MembershipsEngine = await ethers.getContractFactory(
      "MembershipsEngine"
    );
    mockReverseRecords = await MockReverseRecords.deploy();
    [erc721, factory, testEngine, accounts] = await Promise.all([
      ShellERC721.deploy(),
      ShellFactory.deploy(),
      MembershipsEngine.deploy(mockReverseRecords.address),
      ethers.getSigners(),
    ]);
    [a0, a1, a2, a3] = accounts.map((a) => a.address);
    await factory.registerImplementation("erc721", erc721.address);
    const trx = await factory.createCollection(
      "Test",
      "TEST",
      "erc721",
      testEngine.address,
      a0
    );
    const mined = await trx.wait();
    const address = mined.events?.[1].args?.collection;
    collection = ShellERC721.attach(address);
  });

  describe("MembershipsEngine", () => {
    describe("name", () => {
      it("returns the engine name", async () => {
        const resp = await testEngine.name();
        expect(resp).to.eq("memberships-engine-0.0.1");
      })
    })

    describe("supportsInterface", () => {
      it.skip("returns true for IEngine", async () => {
        // TODO need interface id
      })

      it.skip("returns true for IERC165", async () => {
        // TODO need interface id
      })
    })

    describe("afterEngineSet", () => {
      it("reverts for non-0 forks", async () => {
        await expect(testEngine.afterEngineSet(1)).to.be.revertedWith("No new forks");
        await expect(testEngine.afterEngineSet(2)).to.be.revertedWith("No new forks");
        await expect(testEngine.afterEngineSet(4)).to.be.revertedWith("No new forks");
        await expect(testEngine.afterEngineSet(12342340)).to.be.revertedWith("No new forks");
        await expect(testEngine.afterEngineSet(2349)).to.be.revertedWith("No new forks");
        await expect(testEngine.afterEngineSet(99)).to.be.revertedWith("No new forks");
      })

      it("returns for fork 0", async () => {
        await testEngine.afterEngineSet(0);
      })
    })

    async function mintAndCheck(collection: ShellERC721, expectedTokenId: number) {
      const balance = await collection.balanceOf(a1)
      await expect(testEngine.mint(collection.address, a1))
        // should emit transfer from address 0
        .to.emit(collection, "Transfer")
        .withArgs(
          AddressZero,
          a1,
          expectedTokenId
        );
      assert.deepEqual(
        await collection.balanceOf(a1),
        balance.add(1),
        "balance"
      )
    }

    describe("mint", () => {
      it("mints if no previous token", async () => {
        await mintAndCheck(collection, 1)
      })

      it("mints if latest token has expired or is in grace period", async () => {
        await mintAndCheck(collection, 1)
        const expiry = await testEngine.expiryOf(collection.address)
        const gracePeriod = await testEngine.gracePeriodOf(collection.address)
        // after expiry
        let newTime = (await ethers.provider.getBlock("latest")).timestamp + expiry.toNumber()
        await ethers.provider.send('evm_setNextBlockTimestamp', [newTime])
        await mintAndCheck(collection, 2)
        // in grace period
        newTime = (await ethers.provider.getBlock("latest")).timestamp + expiry.toNumber() - gracePeriod.toNumber()
        await ethers.provider.send('evm_setNextBlockTimestamp', [newTime])
        await mintAndCheck(collection, 3)
      })

      it("reverts if not collection owner", async () => {
        const testEngineWrong = testEngine.connect(accounts[1])
        await expect(testEngineWrong.mint(collection.address, a1))
          .to.be.revertedWith("Collection owner only")
      })

      it("reverts if not within grace period or outside expiry on last token", async () => {
        await mintAndCheck(collection, 1)
        const expiry = await testEngine.expiryOf(collection.address)
        const gracePeriod = await testEngine.gracePeriodOf(collection.address)
        // before grace period
        let newTime = (await ethers.provider.getBlock("latest")).timestamp + expiry.toNumber() - gracePeriod.toNumber() - 1
        await ethers.provider.send('evm_setNextBlockTimestamp', [newTime])
        await expect(testEngine.mint(collection.address, a1))
          .to.be.revertedWith("Invalid timing")
      })
    })

    async function batchMintAndCheck(collection: ShellERC721, expectedTokenIds: number[]) {
      const balance1 = await collection.balanceOf(a1)
      const balance2 = await collection.balanceOf(a2)
      const balance3 = await collection.balanceOf(a3)
      await expect(testEngine.batchMint(collection.address, [a1, a2, a3]))
        // should emit transfer from address 0
        .to.emit(collection, "Transfer")
        .withArgs(
          AddressZero,
          a1,
          expectedTokenIds[0]
        );
      assert.deepEqual(
        await collection.balanceOf(a1),
        balance1.add(1),
        "balance1"
      )
      assert.deepEqual(
        await collection.balanceOf(a2),
        balance2.add(1),
        "balance2"
      )
      assert.deepEqual(
        await collection.balanceOf(a3),
        balance3.add(1),
        "balance3"
      )
    }

    describe("batchMint", () => {
      it("mints if no previous tokens", async () => {
        await batchMintAndCheck(collection, [1, 2, 3])
      })

      it("mints if latest tokens have expired or are in grace period", async () => {
        await batchMintAndCheck(collection, [1, 2, 3])
        const expiry = await testEngine.expiryOf(collection.address)
        const gracePeriod = await testEngine.gracePeriodOf(collection.address)
        // after expiry
        let newTime = (await ethers.provider.getBlock("latest")).timestamp + expiry.toNumber()
        await ethers.provider.send('evm_setNextBlockTimestamp', [newTime])
        await batchMintAndCheck(collection, [4, 5, 6])
        // in grace period
        newTime = (await ethers.provider.getBlock("latest")).timestamp + expiry.toNumber() - gracePeriod.toNumber()
        await ethers.provider.send('evm_setNextBlockTimestamp', [newTime])
        await batchMintAndCheck(collection, [7, 8, 9])
      })

      it("reverts if not collection owner", async () => {
        const testEngineWrong = testEngine.connect(accounts[1])
        await expect(testEngineWrong.batchMint(collection.address, [a1]))
          .to.be.revertedWith("Collection owner only")
      })

      it("reverts if not within grace period or outside expiry on last token", async () => {
        await batchMintAndCheck(collection, [1, 2, 3])
        const expiry = await testEngine.expiryOf(collection.address)
        const gracePeriod = await testEngine.gracePeriodOf(collection.address)
        // before grace period
        let newTime = (await ethers.provider.getBlock("latest")).timestamp + expiry.toNumber() - gracePeriod.toNumber() - 1
        await ethers.provider.send('evm_setNextBlockTimestamp', [newTime])
        await expect(testEngine.batchMint(collection.address, [a1, a2, a3]))
          .to.be.revertedWith("Invalid timing")
      })
    })

    describe("activeMemberAt", () => {
      it("returns true if latest token hasn't expired and is held by original owner", async () => {
        await mintAndCheck(collection, 1)
        const block = await ethers.provider.getBlock("latest")
        assert.isTrue(await testEngine.activeMemberAt(collection.address, a1, block.timestamp), "active member")
        const expiry = await testEngine.expiryOf(collection.address)
        assert.isTrue(
          await testEngine.activeMemberAt(collection.address, a1, block.timestamp + expiry.toNumber()),
          "active member"
        )
      })

      it("returns false if no tokens for user", async () => {
        const block = await ethers.provider.getBlock("latest")
        assert.isFalse(await testEngine.activeMemberAt(collection.address, a1, block.timestamp), "active member")
      })

      it("returns false if token fork id isn't 0", async () => {
        await mintAndCheck(collection, 1)
        await collection.connect(accounts[1]).setTokenFork(1, 1)
        const block = await ethers.provider.getBlock("latest")
        assert.isFalse(await testEngine.activeMemberAt(collection.address, a1, block.timestamp), "active member")
      })

      it("returns false for times earlier than latest token was minted", async () => {
        await mintAndCheck(collection, 1)
        const block = await ethers.provider.getBlock("latest")
        assert.isFalse(await testEngine.activeMemberAt(collection.address, a1, block.timestamp - 100), "active member")
      })

      it("returns false for times when latest token is expired", async () => {
        await mintAndCheck(collection, 1)
        const block = await ethers.provider.getBlock("latest")
        const expiry = await testEngine.expiryOf(collection.address)
        assert.isFalse(
          await testEngine.activeMemberAt(collection.address, a1, block.timestamp - expiry.toNumber()),
          "active member"
        )
      })

      it("returns false if latest token is held by new owner", async () => {
        await mintAndCheck(collection, 1)
        await collection.connect(accounts[1]).transferFrom(a1, a2, 1)
        const block = await ethers.provider.getBlock("latest")
        assert.isFalse(await testEngine.activeMemberAt(collection.address, a1, block.timestamp), "active member a1")
        assert.isFalse(await testEngine.activeMemberAt(collection.address, a2, block.timestamp), "active member a2")
      })
    })

    describe("powerOfAt", () => {
      it("returns basePower plus punchDivisor * (# of past memberships - 1) if active member at time", async () => {

      })

      it("returns punchDivisor * # of past memberships, if not active member at time", async () => {

      })
    })

    describe("getTokenURI", () => {

    })

    /**
     * 
     * powerOfAt
     * - behaves correctly with 32+ previous memberships
     *    - # 33 should replace #1 in the punch card
     * 
     * setOptions
     * 
     * basePowerOf
     * 
     * expiryOf
     * 
     * gracePeriodOf
     * 
     * externalUrlOf
     * 
     */
  });
});