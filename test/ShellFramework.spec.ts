import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  ShellFactory,
  ShellERC721,
  MockEngine,
  ShellERC721__factory,
  MockEngine__factory,
} from "../typechain";
import {
  mintEntry,
  mintOptions,
  MINT_DATA_STORAGE,
  FRAMEWORK_STORAGE,
  ENGINE_STORAGE,
} from "./fixtures";

describe("ShellFactory", function () {
  // ---
  // fixtures
  // ---

  let ShellERC721: ShellERC721__factory;
  let MockEngine: MockEngine__factory;
  let erc721: ShellERC721;
  let factory: ShellFactory;
  let mockEngine: MockEngine;
  let accounts: SignerWithAddress[];
  let a0: string, a1: string, a2: string, a3: string;

  beforeEach(async () => {
    ShellERC721 = await ethers.getContractFactory("ShellERC721");
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    MockEngine = await ethers.getContractFactory("MockEngine");
    [erc721, factory, mockEngine, accounts] = await Promise.all([
      ShellERC721.deploy(),
      ShellFactory.deploy(),
      MockEngine.deploy(),
      ethers.getSigners(),
    ]);
    [a0, a1, a2, a3] = accounts.map((a) => a.address);
    await factory.registerImplementation("erc721", erc721.address);
  });

  const createCollection = async (
    name = "Test",
    symbol = "TEST",
    engine = mockEngine.address,
    owner = a0
  ): Promise<ShellERC721> => {
    const trx = await factory.createCollection(
      name,
      symbol,
      "erc721",
      engine,
      owner
    );
    const mined = await trx.wait();
    const address = mined.events?.[1].args?.collection;
    const collection = ShellERC721.attach(address);
    return collection;
  };

  describe("delegated views", () => {
    it("should delegate tokenURI resolution to engine", async () => {
      const collection = await createCollection();
      await mockEngine.mint(collection.address, "Qhash");
      expect(await collection.tokenURI("1")).to.equal("ipfs://ipfs/Qhash");
    });
    it("should resolve royalties from engine", async () => {
      const collection = await createCollection();
      await mockEngine.mint(collection.address, "Qhash");
      const resp = await collection.royaltyInfo("1", parseUnits("1000"));
      expect(resp.receiver).to.equal(a0);
      expect(resp.royaltyAmount).to.equal(parseUnits("100"));
    });
  });
  describe("engine provided mint data", () => {
    it("should write strings in mint data", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(
        collection.address,
        mintEntry(a1, 1, {
          ...mintOptions(),
          stringData: [
            { key: "foo", value: "foo1" },
            { key: "bar", value: "bar1" },
          ],
        })
      );
      expect(
        await collection.readTokenString(MINT_DATA_STORAGE, "1", "foo")
      ).to.equal("foo1");
      expect(
        await collection.readTokenString(MINT_DATA_STORAGE, "1", "bar")
      ).to.equal("bar1");
    });
    it("should write ints in mint data", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(
        collection.address,
        mintEntry(a1, 1, {
          ...mintOptions(),
          intData: [
            { key: "foo", value: 123 },
            { key: "bar", value: 456 },
          ],
        })
      );
      expect(
        await collection.readTokenInt(MINT_DATA_STORAGE, "1", "foo")
      ).to.equal(123);
      expect(
        await collection.readTokenInt(MINT_DATA_STORAGE, "1", "bar")
      ).to.equal(456);
    });
  });
  describe("framework mint data", () => {
    it("should store engine if flag is set", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(collection.address, {
        ...mintEntry(a1, 1, { ...mintOptions(), storeEngine: true }),
      });
      expect(
        await collection.readTokenInt(FRAMEWORK_STORAGE, "1", "engine")
      ).to.equal(mockEngine.address);
    });
    it("should store mintedTo if flag is set", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(collection.address, {
        ...mintEntry(a1, 1, { ...mintOptions(), storeMintedTo: true }),
      });
      expect(
        await collection.readTokenInt(FRAMEWORK_STORAGE, "1", "mintedTo")
      ).to.equal(a1);
    });
    it("should store timestamp if flag is set", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(collection.address, {
        ...mintEntry(a1, 1, { ...mintOptions(), storeTimestamp: true }),
      });
      expect(
        await collection.readTokenInt(FRAMEWORK_STORAGE, "1", "timestamp")
      ).to.equal((await ethers.provider.getBlock("latest")).timestamp);
    });
    it("should store blockNumber if flag is set", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(collection.address, {
        ...mintEntry(a1, 1, { ...mintOptions(), storeBlockNumber: true }),
      });

      expect(
        await collection.readTokenInt(FRAMEWORK_STORAGE, "1", "blockNumber")
      ).to.equal(await ethers.provider.getBlockNumber());
    });
  });
  describe("fork storage", () => {
    it("should revert when fork writing to an invalid location", async () => {
      const collection = await createCollection();
      await expect(
        mockEngine.invalidForkWrite(collection.address, 0)
      ).to.have.revertedWith("WriteNotAllowed()");
    });
    it("should revert when token writing to an invalid location", async () => {
      const collection = await createCollection();
      await expect(
        mockEngine.invalidTokenWrite(collection.address, 1)
      ).to.have.revertedWith("WriteNotAllowed()");
    });
    it("should revert when non-engine attempts fork write", async () => {
      const collection = await createCollection();
      const otherEngine = await MockEngine.deploy();
      await expect(
        otherEngine.writeIntToFork(collection.address, 0, "foo", 123)
      ).to.have.revertedWith("SenderNotEngine()");
    });
    it("should revert when non-engine attempts token write", async () => {
      const collection = await createCollection();
      await mockEngine.mint(collection.address, "Qhash"); // token 1
      const otherEngine = await MockEngine.deploy();
      await expect(
        otherEngine.writeIntToToken(collection.address, "1", "foo", 123)
      ).to.have.revertedWith("SenderNotEngine()");
    });
    it("should allow writing ints to fork storage from engine", async () => {
      const collection = await createCollection();
      await mockEngine.writeIntToFork(collection.address, 0, "foo", 123);
      const value = await collection.readForkInt(ENGINE_STORAGE, 0, "foo");
      expect(value).to.equal(123);
    });

    it("should allow writing ints to token from engine", async () => {
      const collection = await createCollection();
      await mockEngine.mint(collection.address, "Qhash");
      await mockEngine.writeIntToToken(collection.address, "1", "foo", 123);
      const value = await collection.readTokenInt(ENGINE_STORAGE, "1", "foo");
      expect(value).to.equal(123);
    });
    it("should allow writing strings to fork storage from engine", async () => {
      const collection = await createCollection();
      await mockEngine.writeStringToFork(collection.address, 0, "foo", "hey");
      const value = await collection.readForkString(ENGINE_STORAGE, 0, "foo");
      expect(value).to.equal("hey");
    });
    it("should allow writing strings to token from engine", async () => {
      const collection = await createCollection();
      await mockEngine.mint(collection.address, "Qhash");
      await mockEngine.writeStringToToken(
        collection.address,
        "1",
        "foo",
        "hey"
      );
      const value = await collection.readTokenString(
        ENGINE_STORAGE,
        "1",
        "foo"
      );
      expect(value).to.equal("hey");
    });
  });
  describe("implementations", () => {
    it("should work with erc1155 base implementation", async () => {
      const ShellERC1155 = await ethers.getContractFactory("ShellERC1155");
      const erc1155 = await ShellERC1155.deploy();
      await factory.registerImplementation("erc1155", erc1155.address);
      const trx = await factory.createCollection(
        "Test",
        "TEST",
        "erc1155",
        mockEngine.address,
        a0
      );
      const mined = await trx.wait();
      const address = mined.events?.[1].args?.collection;
      const collection = ShellERC1155.attach(address);
      expect(await collection.supportsInterface("0xd9b67a26")).to.equal(true);
      await mockEngine.mint(collection.address, "hash");
      expect(await collection.uri("1")).to.match(/hash/);
    });
    it("erc721: should revert if attempting to mint from non canonical engine", async () => {
      const collection = await createCollection();
      expect(
        collection.mint({
          to: a0,
          amount: 1,
          options: {
            intData: [],
            stringData: [],
            storeBlockNumber: false,
            storeEngine: false,
            storeMintedTo: false,
            storeTimestamp: false,
          },
        })
      ).to.have.revertedWith("SenderNotEngine()");
    });
    it("erc721: should revert if attempting to mint multiple", async () => {
      const collection = await createCollection();
      expect(
        mockEngine.mintMultiple(collection.address, 10)
      ).to.have.revertedWith("InvalidMintAmount()");
    });
  });
  describe("fork management", () => {
    it("should revert if creating a fork with an invalid engine", async () => {
      const collection = await createCollection();
      await expect(
        collection.createFork(collection.address, a0, [])
      ).to.have.revertedWith("InvalidEngine()");
    });
    it("should revert if setting fork engine to invalid engine", async () => {
      const collection = await createCollection();
      await expect(
        collection.setForkEngine("0", collection.address)
      ).to.have.revertedWith("InvalidEngine()");
    });
    it("should revert if changing fork owner as non-owner", async () => {
      const collection = await createCollection();
      const engine2 = await MockEngine.deploy();
      await collection.createFork(engine2.address, a1, []);
      await expect(collection.setForkOwner("1", a0)).to.have.revertedWith(
        "SenderNotForkOwner()"
      );
      await collection.connect(accounts[1]).setForkOwner("1", a0); // no revert
    });
    it("should revert if changing fork engine as non-owner", async () => {
      const collection = await createCollection();
      const engine2 = await MockEngine.deploy();
      await collection.createFork(engine2.address, a1, []);
      await expect(
        collection.setForkEngine("1", mockEngine.address)
      ).to.have.revertedWith("SenderNotForkOwner()");
      await collection
        .connect(accounts[1])
        .setForkEngine("1", mockEngine.address); // no revert
    });
    it("should revert if attempting to fork a non-owned token", async () => {
      const collection = await createCollection();
      const engine2 = await MockEngine.deploy();
      await mockEngine.mint(collection.address, "Qhash");
      await collection.transferFrom(a0, a1, "1");
      await expect(
        collection.createFork(engine2.address, a1, ["1"])
      ).to.have.revertedWith("SenderCannotFork()");
      const collection1 = collection.connect(accounts[1]);
      await collection1.createFork(engine2.address, a1, ["1"]); // no throw
    });
    it("should create forks with auto incrementing ids", async () => {
      const collection = await createCollection();
      const engine2 = await MockEngine.deploy();
      const engine3 = await MockEngine.deploy();
      await collection.createFork(engine2.address, a1, []);
      await collection.createFork(engine3.address, a2, []);
      expect(await collection.getForkEngine(0)).to.equal(mockEngine.address);
      expect(await collection.getForkEngine(1)).to.equal(engine2.address);
      expect(await collection.getForkEngine(2)).to.equal(engine3.address);
      expect((await collection.getFork(0)).owner).to.equal(a0);
      expect((await collection.getFork(1)).owner).to.equal(a1);
      expect((await collection.getFork(2)).owner).to.equal(a2);
    });
    it("should allow forking tokens during fork creation", async () => {
      const collection = await createCollection();
      const engine2 = await MockEngine.deploy();
      await mockEngine.mint(collection.address, "Qhash");
      await mockEngine.mint(collection.address, "Qhash");
      await mockEngine.mint(collection.address, "Qhash");
      await collection.createFork(engine2.address, a0, ["2", "3"]);
      expect(await collection.getTokenEngine("1")).to.equal(mockEngine.address);
      expect(await collection.getTokenEngine("2")).to.equal(engine2.address);
      expect(await collection.getTokenEngine("3")).to.equal(engine2.address);
      expect(await collection.getTokenForkId("1")).to.equal("0");
      expect(await collection.getTokenForkId("2")).to.equal("1");
      expect(await collection.getTokenForkId("3")).to.equal("1");
    });
    it("should allow nft owner to batch set token fork", async () => {
      const collection = await createCollection();
      const engine2 = await MockEngine.deploy();
      await collection.createFork(engine2.address, a1, []);
      await mockEngine.mint(collection.address, "Qhash");
      await mockEngine.mint(collection.address, "Qhash");
      await mockEngine.mint(collection.address, "Qhash");
      await collection.setTokenForks(["2", "3"], "1");
      expect(await collection.getTokenForkId("1")).to.equal("0");
      expect(await collection.getTokenForkId("2")).to.equal("1");
      expect(await collection.getTokenForkId("3")).to.equal("1");
    });
    it("should revert if non nft owner attempts to batch set token fork", async () => {
      const collection = await createCollection();
      const engine2 = await MockEngine.deploy();
      await collection.createFork(engine2.address, a1, []);
      await mockEngine.mint(collection.address, "Qhash");
      await mockEngine.mint(collection.address, "Qhash");
      await mockEngine.mint(collection.address, "Qhash");
      await expect(
        collection.connect(accounts[1]).setTokenForks(["2", "3"], "1")
      ).to.have.revertedWith("SenderCannotFork()");
    });
  });
});
