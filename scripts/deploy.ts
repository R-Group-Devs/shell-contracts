import { ethers } from "hardhat";

async function main() {
  const CollectionFactory = await ethers.getContractFactory(
    "CollectionFactory"
  );
  const factory = await CollectionFactory.deploy();
  await factory.deployed();
  console.log(`🐚 shell has been deployed to: ${factory.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
