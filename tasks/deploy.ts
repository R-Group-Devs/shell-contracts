import { task } from "hardhat/config";
import { readDeploymentsFile, writeDeploymentsFile } from "./file";

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

    if (network.name !== "localhost" && network.name !== "hardhat") {
      if (contract === "ShellFactory") {
        console.log("updating factory-deployments.json ...");
        const entries = await readDeploymentsFile();
        entries[network.name] = { address };
        await writeDeploymentsFile(entries);
      }

      console.log("waiting 60 seconds before attempting to verify ...");
      await new Promise((resolve) => setTimeout(resolve, 60 * 1000));

      console.log("verifying...");
      try {
        await run("verify:verify", {
          address: deployed.address,
          constructorArguments: [],
        });
      } catch (err) {
        console.warn("Verfication error:", err);
      }
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

// task("deploy:squadz", "Deploy and register SQUADZ")
//   .addOptionalParam<boolean>("deployShellFactory", "Deploy new shell factory?", false, types.boolean)
//   .addOptionalParam<string>("reverseRecords", "Existing name system for personalized descriptor")
//   .setAction(async ({ deployShellFactory, reverseRecords }, { ethers, run, network }) => {
//     // Deploy or get shell factory
//     const entries = await readDeploymentsFile();
//     let shellFactory
//     const entry = entries[network.name]
//     const ShellFactory = await ethers.getContractFactory("ShellFactory");
//     const implementationName = "shell-erc721-v1";
//     if (entry !== undefined && deployShellFactory !== true) {
//       shellFactory = ShellFactory.attach(entry.address);
//     } else {
//       if (deployShellFactory !== true) {
//         throw new Error(`No shell factory found on ${network.name}. Run again with '--deploy-shell-factory true' to deploy a new one.`);
//       } else {
//         const shellFactoryAddr = await run("deploy", { contract: "ShellFactory" });
//         shellFactory = ShellFactory.attach(shellFactoryAddr)
//         await run("deploy:implementation", { contract: "ShellERC721", implementation: implementationName });
//       }
//     }

//     const signers = await ethers.getSigners()
//     const owner = await signers[0].getAddress()

//     const SNSEngine = await ethers.getContractFactory("SNSEngine");
//     let snsEngine
//     if (reverseRecords === undefined) {
//       // Deploy SNSEngine
//       const snsEngineAddr = await run("deploy", { contract: "SNSEngine" });
//       snsEngine = SNSEngine.attach(snsEngineAddr);
//       // Deploy new SNS using shell factory and SNSEngine or specify revese records address
//       const tx = await shellFactory.createCollection("Simple Name System", "SNS", implementationName, snsEngine.address, owner)
//       const rec = await tx.wait();
//       if (rec.events === undefined) throw new Error('No event logs');
//       const collectionAddr = rec.events[4].args?.collection;
//       reverseRecords = await snsEngine.getSNSAddr(collectionAddr);
//       try {
//         await run("verify:verify", {
//           address: reverseRecords,
//           constructorArguments: [snsEngine.address, collectionAddr],
//         });
//       } catch (err) {
//         console.warn('Verfication error:', err);
//       }
//     } else {
//       snsEngine = SNSEngine.attach(reverseRecords);
//     }

//     // Deploy new Simple Descriptor pointing at reverse records address
//     const descriptorFact = await ethers.getContractFactory("SimpleDescriptor");
//     const descriptor = await descriptorFact.deploy(reverseRecords);
//     await descriptor.deployed();

//     console.log(`Simple Descriptor deployed to ${descriptor.address} on ${network.name}.`);

//     console.log("waiting 60 seconds before attempting to verify ...");
//     await new Promise((resolve) => setTimeout(resolve, 60 * 1000));

//     console.log("verifying...");
//     try {
//       await run("verify:verify", {
//         address: descriptor.address,
//         constructorArguments: [reverseRecords],
//       });
//     } catch (err) {
//       console.warn('Verfication error:', err);
//     }

//     // Deploy new Squadz Engine with Simple Descriptor as default descriptor
//     const squadzFact = await ethers.getContractFactory("SquadzEngine");
//     const squadzEngine = await squadzFact.deploy(descriptor.address);
//     await squadzEngine.deployed();

//     console.log(`SQUADZ engine deployed to ${squadzEngine.address} on ${network.name}.`);
//     console.log("waiting 60 seconds before attempting to verify ...");
//     await new Promise((resolve) => setTimeout(resolve, 60 * 1000));

//     console.log("verifying...");
//     try {
//       await run("verify:verify", {
//         address: squadzEngine.address,
//         constructorArguments: [descriptor.address],
//       });
//     } catch (err) {
//       console.warn('Verfication error:', err)
//     }

//     return { snsEngine, squadzEngine }
//   });
