import { ethers } from "hardhat";

async function main() {
  const ShellFactory = await ethers.getContractFactory("ShellFactory");
  const factory = await ShellFactory.deploy();
  await factory.deployed();
  console.log(`🐚 shell has been deployed to: ${factory.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
