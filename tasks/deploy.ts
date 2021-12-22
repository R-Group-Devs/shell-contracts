import { task } from "hardhat/config";
import { promises } from "fs";
import { join } from "path";

const { readFile, writeFile } = promises;
const filepath = join(__dirname, "./deployments.json");

interface DeploymentsFile {
  [network: string]:
    | undefined
    | {
        address: string;
      };
}

const writeDeploymentsFile = async (contents: unknown) => {
  await writeFile(filepath, JSON.stringify(contents, null, 2));
};

const readDeploymentsFile = async (): Promise<DeploymentsFile> => {
  const file = await readFile(filepath);
  const entries = JSON.parse(file.toString());
  return entries;
};

task("deploy", "Deploy a contract")
  .addParam<string>("contract", "Contract to deploy")
  .setAction(async ({ contract }, { ethers, run, network }) => {
    console.log("compiling all contracts...");
    await run("compile");

    const ContractFactory = await ethers.getContractFactory(contract);

    console.log(`Deploying ${contract} ...`);
    const deployed = await ContractFactory.deploy();
    await deployed.deployed();
    const address = deployed.address;

    console.log("\n\n---");
    console.log(`🐚 ${contract}: ${address}`);
    console.log("---\n\n");

    if (contract === "ShellFactory") {
      console.log("updating factory-deployments.json...");
      const entries = await readDeploymentsFile();
      entries[network.name] = { address };
      await writeDeploymentsFile(entries);
    }

    console.log("waiting 60 seconds before attempting to verify...");
    await new Promise((resolve) => setTimeout(resolve, 60 * 1000));

    console.log("verifying...");
    await run("verify:verify", {
      address: deployed.address,
      constructorArguments: [],
    });

    return address;
  });

task(
  "deploy:implementation",
  "Deploy and register a shell implementation contract"
)
  .addParam<string>("contract", "Contract to deploy and register")
  .addParam<string>(
    "implementation",
    "Name to use during implementation registration"
  )
  .setAction(async ({ contract, implementation }, { ethers, run, network }) => {
    const address: string = await run("deploy", { contract });
    const entry = (await readDeploymentsFile())[network.name];
    if (!entry) {
      throw new Error(`no deployment entry for network: ${network.name}`);
    }

    console.log("registering implementation with factory...");
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const factory = ShellFactory.attach(entry.address);
    const trx = await factory.registerImplementation(implementation, address);
    await trx.wait();

    console.log(`${implementation} registered with ShellFactory`);
  });
