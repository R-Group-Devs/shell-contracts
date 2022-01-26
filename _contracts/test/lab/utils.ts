
import { ethers } from "hardhat";
import { ShellERC721, ShellFactory } from "../../typechain"

export const createCollection = async (
  name = "Test",
  symbol = "TEST",
  engine: string,
  owner: string,
  factory: ShellFactory,
  eventIndex: number
): Promise<ShellERC721> => {
  const trx = await factory.createCollection(
    name,
    symbol,
    "erc721",
    engine,
    owner
  );
  const mined = await trx.wait();
  const address = mined.events?.[eventIndex].args?.collection;
  const collection: ShellERC721 = (await ethers.getContractFactory("ShellERC721")).attach(address);
  return collection;
};