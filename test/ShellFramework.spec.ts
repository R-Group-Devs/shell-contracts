import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumberish } from "ethers";
import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  ShellFactory,
  ShellERC721,
  MockEngine,
  ShellERC721__factory,
} from "../typechain";

interface MintData {
  storeEngine: boolean;
  storeMintedTo: boolean;
  storeTimestamp: boolean;
  storeBlockNumber: boolean;
  stringData: Array<{ key: string; value: string }>;
  intData: Array<{ key: string; value: BigNumberish }>;
}

const mintData = (): MintData => {
  return {
    storeEngine: false,
    storeMintedTo: false,
    storeTimestamp: false,
    storeBlockNumber: false,
    stringData: [],
    intData: [],
  };
};

const ENGINE_STORAGE = 1;
const MINT_DATA_STORAGE = 2;
const FRAMEWORK_STORAGE = 3;

describe("ShellFactory", function () {
  // ---
  // fixtures
  // ---

  let ShellERC721: ShellERC721__factory;
  let erc721: ShellERC721;
  let factory: ShellFactory;
  let mockEngine: MockEngine;
  let accounts: SignerWithAddress[];
  let a0: string, a1: string, a2: string, a3: string;

  beforeEach(async () => {
    ShellERC721 = await ethers.getContractFactory("ShellERC721");
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const MockEngine = await ethers.getContractFactory("MockEngine");
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
    const address = mined.events?.[2].args?.collection;
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
  describe("engine installs", async () => {
    it("should revert if invalid engine", async () => {
      const collection = await createCollection();
      expect(collection.installEngine(erc721.address)).to.be.revertedWith(
        "shell: invalid engine"
      );
    });
    it("should emit an EngineInstalled event", async () => {
      const collection = await createCollection();
      expect(collection.installEngine(mockEngine.address))
        .to.emit(collection, "EngineInstalled")
        .withArgs(mockEngine.address);
    });
    it("should revert if non-owner attempts engine install", async () => {
      const collection = await createCollection();
      const c1 = collection.connect(accounts[1]);
      expect(c1.installEngine(mockEngine.address)).to.be.revertedWith(
        "Ownable: caller is not owner"
      );
    });
  });
  describe("engine provided mint data", () => {
    it("should write strings in mint data", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(collection.address, a1, {
        ...mintData(),
        stringData: [
          { key: "foo", value: "foo1" },
          { key: "bar", value: "bar1" },
        ],
      });
      expect(
        await collection.readTokenString(MINT_DATA_STORAGE, "1", "foo")
      ).to.equal("foo1");
      expect(
        await collection.readTokenString(MINT_DATA_STORAGE, "1", "bar")
      ).to.equal("bar1");
    });
    it("should write ints in mint data", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(collection.address, a1, {
        ...mintData(),
        intData: [
          { key: "foo", value: 123 },
          { key: "bar", value: 456 },
        ],
      });
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
      await mockEngine.mintPassthrough(collection.address, a1, {
        ...mintData(),
        storeEngine: true,
      });
      expect(
        await collection.readTokenInt(FRAMEWORK_STORAGE, "1", "engine")
      ).to.equal(mockEngine.address);
    });
    it("should store mintedTo if flag is set", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(collection.address, a1, {
        ...mintData(),
        storeMintedTo: true,
      });
      expect(
        await collection.readTokenInt(FRAMEWORK_STORAGE, "1", "mintedTo")
      ).to.equal(a1);
    });
    it("should store timestamp if flag is set", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(collection.address, a1, {
        ...mintData(),
        storeTimestamp: true,
      });
      expect(
        await collection.readTokenInt(FRAMEWORK_STORAGE, "1", "timestamp")
      ).to.equal((await ethers.provider.getBlock("latest")).timestamp);
    });
    it("should store blockNumber if flag is set", async () => {
      const collection = await createCollection();
      await mockEngine.mintPassthrough(collection.address, a1, {
        ...mintData(),
        storeBlockNumber: true,
      });
      expect(
        await collection.readTokenInt(FRAMEWORK_STORAGE, "1", "blockNumber")
      ).to.equal(await ethers.provider.getBlockNumber());
    });
  });
  describe("engine storage", () => {
    it("should allow writing ints to collection from engine", async () => {
      const collection = await createCollection();
      await mockEngine.writeIntToCollection(collection.address, "foo", 123);
      const value = await collection.readCollectionInt(ENGINE_STORAGE, "foo");
      expect(value).to.equal(123);
    });
    it("should allow writing ints to token from engine", async () => {
      const collection = await createCollection();
      await mockEngine.mint(collection.address, "Qhash");
      await mockEngine.writeIntToToken(collection.address, "1", "foo", 123);
      const value = await collection.readTokenInt(ENGINE_STORAGE, "1", "foo");
      expect(value).to.equal(123);
    });
    it("should revert if non-engine attempts to write to collection", async () => {
      const collection = await createCollection();
      await mockEngine.mint(collection.address, "Qhash");
    });
  });
});
