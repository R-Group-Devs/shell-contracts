import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  ShellFactory,
  ShellERC721,
  MockEngine,
  ShellERC721__factory,
} from "../typechain";

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
});
