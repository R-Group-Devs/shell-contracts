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
export const FORK_STORAGE = 4;
