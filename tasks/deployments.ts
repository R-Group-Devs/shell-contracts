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

export const writeDeploymentsFile = async (contents: unknown) => {
  await writeFile(filepath, JSON.stringify(contents, null, 2));
};

export const readDeploymentsFile = async (): Promise<DeploymentsFile> => {
  const file = await readFile(filepath);
  const entries = JSON.parse(file.toString());
  return entries;
};
