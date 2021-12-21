import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  ShellFactory,
  ShellERC721,
  ShellERC721__factory,
  MockEngine,
} from "../typechain";

describe("CollectionFactory", function () {
  // ---
  // fixtures
  // ---

  let Collection: ShellERC721__factory;
  let factory: ShellFactory;
  let mockEngine: MockEngine;
  let accounts: SignerWithAddress[];
  let a0: string, a1: string, a2: string, a3: string;

  beforeEach(async () => {
    Collection = await ethers.getContractFactory("ShellERC721");
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const MockEngine = await ethers.getContractFactory("MockEngine");
    [factory, mockEngine, accounts] = await Promise.all([
      ShellFactory.deploy(),
      MockEngine.deploy(),
      ethers.getSigners(),
    ]);
    // give infinite allowance for a0 to hv
    [a0, a1, a2, a3] = accounts.map((a) => a.address);
  });

  const createCollection = async (
    name = "Test",
    symbol = "TEST",
    engine = mockEngine.address,
    owner = a0
  ): Promise<ShellERC721> => {
    const trx = await factory.createCollection(name, symbol, engine, owner);
    const mined = await trx.wait();
    const address = mined.events?.[2].args?.collection;
    const collection = Collection.attach(address);
    return collection;
  };

  describe("basics", () => {
    it("should deploy new collections", async () => {
      const collection = await createCollection();
      expect(await collection.name()).to.equal("Test");
      expect(await collection.symbol()).to.equal("TEST");
    });
    it("should delegate tokenURI resolution to engine", async () => {
      const collection = await createCollection();
      await mockEngine.mint(collection.address, "Qhash");
      expect(await collection.tokenURI("1")).to.equal("ipfs://ipfs/Qhash");
    });
  });
});
