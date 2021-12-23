import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  ShellFactory,
  ShellERC721,
  MockEngine,
  ShellERC721__factory,
} from "../typechain";

describe("CollectionFactory", function () {
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
    // give infinite allowance for a0 to hv
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

  describe("implementation registration", () => {
    it("should revert if registering the same name more than once", async () => {
      await factory.registerImplementation("foo", erc721.address);
      expect(
        factory.registerImplementation("foo", erc721.address)
      ).to.be.revertedWith("shell: implementation exists");
    });
    it("should revert if implementation does not implement IShellFramework", async () => {
      expect(
        factory.registerImplementation("foo", mockEngine.address)
      ).to.be.revertedWith("shell: invalid implementation");
    });
    it("should not allow non-owner to register implementation", async () => {
      const factory1 = factory.connect(accounts[1]);
      expect(
        factory1.registerImplementation("foo", erc721.address)
      ).to.be.revertedWith("Ownable: caller is not owner");
    });
    it("should emit an ImplementationRegistered event on registration", async () => {
      expect(factory.registerImplementation("foo", erc721.address))
        .to.emit(factory, "ImplementationRegistered")
        .withArgs("foo", erc721.address);
    });
  });

  describe("creation collection", async () => {
    it("should revert if launching a collection with an invalid name", async () => {
      expect(
        factory.createCollection(
          "name",
          "symbol",
          "invalid name",
          mockEngine.address,
          a0
        )
      ).to.be.revertedWith("shell: implementation not found");
    });
    it("should emit CollectionCreated when launching a collection", async () => {
      const trx = await factory.createCollection(
        "name",
        "symbol",
        "erc721",
        mockEngine.address,
        a0
      );
      const mined = await trx.wait();
      const address = mined.events?.[2].args?.collection;
      const implementation = mined.events?.[2].args?.implementation;
      expect(address).to.match(/^0x/); //
      expect(implementation).to.equal(erc721.address);
    });
  });

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
