/**
 * Should create a valid SVG
 * Should work with either ENS or SNS for reverse records
 */

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  SNS,
  SNSEngine,
  SimpleDescriptor,
  ShellERC721,
  ShellERC721__factory,
  ShellFactory
} from "../../typechain";
import { createCollection } from "./utils"

describe("SimpleDescriptor", function () {
  // ---
  // fixtures
  // ---

  let ShellERC721: ShellERC721__factory;
  let erc721: ShellERC721;
  let collection: ShellERC721;
  let factory: ShellFactory;
  let snsEngine: SNSEngine;
  let snsAddress: string;
  let simpleDescriptor: SimpleDescriptor;
  let accounts: SignerWithAddress[];
  let a0: string, a1: string, a2: string, a3: string;

  beforeEach(async () => {
    ShellERC721 = await ethers.getContractFactory("ShellERC721");
    const ShellFactory = await ethers.getContractFactory("ShellFactory");
    const SNSEngine = await ethers.getContractFactory("SNSEngine");
    [erc721, factory, snsEngine, accounts] = await Promise.all([
      ShellERC721.deploy(),
      ShellFactory.deploy(),
      SNSEngine.deploy(),
      ethers.getSigners()
    ]);
    [a0, a1, a2, a3] = accounts.map((a) => a.address);
    await factory.registerImplementation("erc721", erc721.address);
    collection = await createCollection("Test", "TST", snsEngine.address, a0, factory, 4);
    await snsEngine.setPrice(collection.address, 1);
    await snsEngine.mintAndSet(collection.address, "Testo", { value: 1 });
    snsAddress = await snsEngine.getSNSAddr(collection.address);
    const SimpleDescriptor = await ethers.getContractFactory("SimpleDescriptor");
    simpleDescriptor = await SimpleDescriptor.deploy(snsAddress);
  });

  it("creates a valid SVG", async () => {
    await printURI(simpleDescriptor, collection.address, 100, a0);
  })

  it("works with ENS", async () => {
    const SimpleDescriptor = await ethers.getContractFactory("SimpleDescriptor");
    // using ENS' mainnet reverse records contract
    const simpleDescriptor = await SimpleDescriptor.deploy("0x3671aE578E63FdF66ad4F3E12CC0c0d71Ac7510C");
    await printURI(simpleDescriptor, collection.address, 100, "0x4171160dB0e7E2C75A4973b7523B437C010Dd9d4");
  })
})

async function printURI(
    sd: SimpleDescriptor, 
    collectionAddr: string, 
    tokenId: number, 
    holderAddr: string
): Promise<string> {
    const uri = "data:application/json;base64,eyAiaWQiOiAxLCAib3duZXJOYW1lIjogIiIsICJ0b2tlbk5hbWUiOiAiU1FVQURaIFRlc3QiLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTXpBd0lpQm9aV2xuYUhROUlqUXdNQ0lnZG1sbGQwSnZlRDBpTUNBd0lETXdNQ0EwTURBaUlHWnBiR3c5SW01dmJtVWlJSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SStQSEpsWTNRZ2QybGtkR2c5SWpNd01DSWdhR1ZwWjJoMFBTSTBNREFpSUhKNFBTSXhOREFpSUdacGJHdzlJblZ5YkNnamNHRnBiblF3WDNKaFpHbGhiRjh4WHpNcElpOCtQSE4wZVd4bFBpNXRZV2x1SUhzZ1ptOXVkRG9nTWpSd2VDQnpZVzV6TFhObGNtbG1PeUJtYVd4c09uSm5ZbUVvTlRjc01qTTRMREV6T1N3Z01TazdJSDA4TDNOMGVXeGxQangwWlhoMElIZzlJalV3SlNJZ2VUMGlNVGMyY0hnaUlIUmxlSFF0WVc1amFHOXlQU0p0YVdSa2JHVWlJR05zWVhOelBTSnRZV2x1SWo0OEwzUmxlSFErUEhSbGVIUWdlRDBpTlRBbElpQjVQU0l5TURad2VDSWdkR1Y0ZEMxaGJtTm9iM0k5SW0xcFpHUnNaU0lnWTJ4aGMzTTlJbTFoYVc0aVBsTlJWVUZFV2lCVVpYTjBQQzkwWlhoMFBqeDBaWGgwSUhnOUlqVXdKU0lnZVQwaU1qTTJjSGdpSUhSbGVIUXRZVzVqYUc5eVBTSnRhV1JrYkdVaUlHTnNZWE56UFNKdFlXbHVJajR4UEM5MFpYaDBQanhrWldaelBqeHlZV1JwWVd4SGNtRmthV1Z1ZENCcFpEMGljR0ZwYm5Rd1gzSmhaR2xoYkY4eFh6TWlJR040UFNJd0lpQmplVDBpTUNJZ2NqMGlNU0lnWjNKaFpHbGxiblJWYm1sMGN6MGlkWE5sY2xOd1lXTmxUMjVWYzJVaUlHZHlZV1JwWlc1MFZISmhibk5tYjNKdFBTSjBjbUZ1YzJ4aGRHVW9NVFV3SURJd01Da2djbTkwWVhSbEtEa3dLU0J6WTJGc1pTZ3lNRGNnTVRjd0tTSStQSE4wYjNBZ2MzUnZjQzFqYjJ4dmNqMGljbWRpWVNneE9EVXNNVEV4TERFeUxDQXhLU0l2UGp4emRHOXdJRzltWm5ObGREMGlNU0lnYzNSdmNDMWpiMnh2Y2owaWNtZGlZU2cxTnl3eU16Z3NNVE01TENBeEtTSXZQand2Y21Ga2FXRnNSM0poWkdsbGJuUStQQzlrWldaelBqd3ZjM1puUGc9PSIgfQ=="
    const [, jsonBase64] = uri.split(",");
    const json = Buffer.from(jsonBase64, "base64").toString();
    const [, imageBase64] = JSON.parse(json).image.split(",");
    const svg = Buffer.from(imageBase64, "base64").toString()
    console.log('SVG', svg);
    return svg;
}