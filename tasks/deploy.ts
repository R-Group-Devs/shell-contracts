import { task, types } from "hardhat/config";
import { promises } from "fs";
import { join } from "path";

import { ShellFactory } from "../typechain/ShellFactory";
import { SimpleDescriptor } from "../typechain/SimpleDescriptor";
import { SNSEngine } from "../typechain/SNSEngine";
import { SquadzEngine } from "../typechain/SquadzEngine";

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
    console.log("compiling all contracts ...");
    await run("compile");

    const ContractFactory: any = await ethers.getContractFactory(contract);

    console.log(`Deploying ${contract} ...`);
    const deployed = await ContractFactory.deploy();
    await deployed.deployed();
    const address = deployed.address;

    console.log("\n\n---");
    console.log(`🐚 ${contract}: ${address}`);
    console.log("---\n\n");

    if (contract === "ShellFactory") {
      console.log("updating factory-deployments.json ...");
      const entries = await readDeploymentsFile();
      entries[network.name] = { address };
      await writeDeploymentsFile(entries);
    }

    if (network.name !== "localhost" && network.name !== "hardhat") {
      console.log("waiting 60 seconds before attempting to verify ...");
      await new Promise((resolve) => setTimeout(resolve, 60 * 1000));

      console.log("verifying...");
      await run("verify:verify", {
        address: deployed.address,
        constructorArguments: [],
      });
    }
    
    return address;
  });

task("register", "Register a shell implementation contract")
  .addParam<string>("address", "Deployed contract address")
  .addParam<string>(
    "implementation",
    "Name to use during implementation registration"
  )
  .setAction(async ({ address, implementation }, { ethers, run, network }) => {
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const entry = (await readDeploymentsFile())[network.name];
    if (!entry) {
      throw new Error(`no deployment entry for network: ${network.name}`);
    }
    const factory = ShellFactory.attach(entry.address);

    console.log("registering implementation with factory ...");
    const trx = await factory.registerImplementation(implementation, address);
    await trx.wait();

    console.log(`${implementation} registered with ShellFactory`);
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
    await run("register", { address, implementation });
  });

interface SquadzDeployment {
  snsEngine: SNSEngine, 
  squadzEngine: SquadzEngine
}

task("deploy:squadz", "Deploy and register SQUADZ")
  .addOptionalParam<boolean>("deployShellFactory", "Deploy new shell factory?", false, types.boolean)
  .addOptionalParam<string>("reverseRecords", "Existing name system for personalized descriptor")
  .setAction(async ({ deployShellFactory, reverseRecords }, { ethers, run, network }): Promise<SquadzDeployment> => {
    // Deploy or get shell factory
    const entries = await readDeploymentsFile();
    let shellFactory: ShellFactory
    const entry = entries[network.name]
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const implementationName = "shell-erc721-v1";
    if (entry !== undefined && deployShellFactory !== true) {
      shellFactory = ShellFactory.attach(entry.address);
    } else {
      if (deployShellFactory !== true) {
        throw new Error(`No shell factory found on ${network.name}. Run again with '--deploy-shell-factory true' to deploy a new one.`);
      } else {
        const shellFactoryAddr = await run("deploy", { contract: "ShellFactory" });
        shellFactory = ShellFactory.attach(shellFactoryAddr)
        await run("deploy:implementation", { contract: "ShellERC721", implementation: implementationName });
      }
    }

    const signers = await ethers.getSigners()
    const owner = await signers[0].getAddress()

    const SNSEngine = await ethers.getContractFactory("SNSEngine");
    let snsEngine: SNSEngine
    if (reverseRecords === undefined) {
      // Deploy SNSEngine
      const snsEngineAddr = await run("deploy", { contract: "SNSEngine" });
      snsEngine = SNSEngine.attach(snsEngineAddr);
      // Deploy new SNS using shell factory and SNSEngine or specify revese records address
      const tx = await shellFactory.createCollection("Simple Name System", "SNS", implementationName, snsEngine.address, owner)
      const rec = await tx.wait();
      if (rec.events === undefined) throw new Error('No event logs');
      const collectionAddr = rec.events[4].args?.collection;
      reverseRecords = await snsEngine.getSNSAddr(collectionAddr);
    } else {
      snsEngine = SNSEngine.attach(reverseRecords);
    }
    
    // Deploy new Simple Descriptor pointing at reverse records address
    const descriptorFact = await ethers.getContractFactory("SimpleDescriptor");
    const descriptor: SimpleDescriptor = await descriptorFact.deploy(reverseRecords);
    await descriptor.deployed();

    // Deploy new Squadz Engine with Simple Descriptor as default descriptor
    const squadzFact = await ethers.getContractFactory("SquadzEngine");
    const squadzEngine: SquadzEngine = await squadzFact.deploy(descriptor.address);
    await squadzEngine.deployed();
    
    console.log(`SQUADZ engine deployed to ${squadzEngine.address} on ${network.name}`);
    return { snsEngine, squadzEngine }
  });
