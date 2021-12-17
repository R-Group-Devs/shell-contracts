import { ethers } from "hardhat";

async function main() {
  const MockEngine = await ethers.getContractFactory("MockEngine");
  const RGroupPlaceholder = await ethers.getContractFactory(
    "RGroupPlaceholder"
  );
  const [mock, rgroup] = await Promise.all([
    await MockEngine.deploy(),
    await RGroupPlaceholder.deploy(),
  ]);
  await Promise.all([mock.deployed(), rgroup.deployed()]);
  console.log(`🐚 MockEngine has been deployed to: ${mock.address}`);
  console.log(`🐚 RGroupPlaceholder has been deployed to: ${rgroup.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
