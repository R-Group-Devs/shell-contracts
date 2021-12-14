import { ethers } from "hardhat";

async function main() {
  const MockEngine = await ethers.getContractFactory("MockEngine");
  const mockEngine = await MockEngine.deploy();
  await mockEngine.deployed();
  console.log(`🐚 MockEngine has been deployed to: ${mockEngine.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
