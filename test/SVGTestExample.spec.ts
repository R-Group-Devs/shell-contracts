import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  ShellFactory,
  ShellERC721,
  ShellERC721__factory,
  SVGTextExample,
} from "../typechain";
import { metadataFromTokenURI, svgFromImageData } from "./fixtures";

describe("SVGTextExample", function () {
  // ---
  // fixtures
  // ---

  let ShellERC721: ShellERC721__factory;
  let erc721: ShellERC721;
  let factory: ShellFactory;
  let accounts: SignerWithAddress[];
  let testEngine: SVGTextExample;
  let a0: string, a1: string, a2: string, a3: string;

  beforeEach(async () => {
    ShellERC721 = await ethers.getContractFactory("ShellERC721");
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const SVGTextExample = await ethers.getContractFactory("SVGTextExample");
    [erc721, factory, testEngine, accounts] = await Promise.all([
      ShellERC721.deploy(),
      ShellFactory.deploy(),
      SVGTextExample.deploy(),
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

  describe("SVGTextExample", () => {
    it("should mint with provided data", async () => {
      const collection = await createCollection();
      await testEngine.mint(collection.address, "Brandon", "greetings");
      const resp = await collection.tokenURI("1");
      const metadata = metadataFromTokenURI(resp);
      expect(metadata.name).to.equal("Member: Brandon");
      expect(metadata.description).to.include("greetings");
    });
    it("should generate valid svg", async () => {
      const collection = await createCollection();
      await testEngine.mint(collection.address, "Brandon", "greetings");
      const metadata = metadataFromTokenURI(await collection.tokenURI("1"));
      const svg = svgFromImageData(metadata.image);
      expect(svg).to.match(/<svg xmlns="http:\/\/www.w3.org\/2000\/svg"/);
    });
  });
});
