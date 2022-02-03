import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { parseUnits } from "ethers/lib/utils";
import { ethers } from "hardhat";
import {
  ShellFactory,
  ShellERC721,
  MockEngine,
  ShellERC721__factory,
  PlaygroundsGenesisEngine,
} from "../typechain";
import {
  mintEntry,
  mintOptions,
  MINT_DATA_STORAGE,
  FRAMEWORK_STORAGE,
  FORK_STORAGE,
  ENGINE_STORAGE,
  metadataFromTokenURI,
} from "./fixtures";

describe("ShellFactory", function () {
  // ---
  // fixtures
  // ---

  let ShellERC721: ShellERC721__factory;
  let erc721: ShellERC721;
  let factory: ShellFactory;
  let accounts: SignerWithAddress[];
  let testEngine: PlaygroundsGenesisEngine;
  let a0: string, a1: string, a2: string, a3: string;

  beforeEach(async () => {
    ShellERC721 = await ethers.getContractFactory("ShellERC721");
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const PlaygroundsGenesisEngine = await ethers.getContractFactory(
      "PlaygroundsGenesisEngine"
    );
    [erc721, factory, testEngine, accounts] = await Promise.all([
      ShellERC721.deploy(),
      ShellFactory.deploy(),
      PlaygroundsGenesisEngine.deploy(),
      ethers.getSigners(),
    ]);
    [a0, a1, a2, a3] = accounts.map((a) => a.address);
    await factory.registerImplementation("erc721", erc721.address);
  });

  const createCollection = async (
    name = "Test",
    symbol = "TEST",
    engine = testEngine.address,
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

  describe.only("PlaygroundsGenesisEngine", () => {
    it("return correct name", async () => {
      const resp = await testEngine.name();
      expect(resp).to.eq("playgrounds-genesis-v0");
    });
    it("should mint with no code", async () => {
      const collection = await createCollection();
      await testEngine.mint(collection.address, "");
      const metadata = metadataFromTokenURI(await collection.tokenURI("1"));
      expect(metadata.name).to.contain("#1");
    });
  });
});
