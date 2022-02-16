import { BigNumberish } from "ethers";

export interface MintOptions {
  storeEngine: boolean;
  storeMintedTo: boolean;
  storeTimestamp: boolean;
  storeBlockNumber: boolean;
  stringData: Array<{ key: string; value: string }>;
  intData: Array<{ key: string; value: BigNumberish }>;
}

export interface MintEntry {
  to: string;
  amount: number;
  options: MintOptions;
}

export const mintOptions = (): MintOptions => {
  return {
    storeEngine: false,
    storeMintedTo: false,
    storeTimestamp: false,
    storeBlockNumber: false,
    stringData: [],
    intData: [],
  };
};

export const mintEntry = (
  to: string,
  amount = 1,
  options = mintOptions()
): MintEntry => {
  return { to, amount, options };
};

export const ENGINE_STORAGE = 1;
export const MINT_DATA_STORAGE = 2;
export const FRAMEWORK_STORAGE = 3;

interface MaybeMetadata {
  name?: string;
  description?: string;
  image?: string;
  external_url?: string;
  attributes?: Array<{ trait_type: string; value: string }>;
}

export const metadataFromTokenURI = (tokenUri: string): MaybeMetadata => {
  const [prefix, encoded] = tokenUri.split(",");
  if (prefix !== "data:application/json;base64") {
    throw new Error("invalid token uri");
  }
  const json = Buffer.from(encoded, "base64").toString();
  const parsed = JSON.parse(json);
  return parsed;
};
