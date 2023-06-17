// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
import { ethers, network  } from "hardhat";
import {
  proxies,
  baseURIs,
  TablelandNetworkConfig,
} from "@tableland/evm/network";

async function main() {
  const registryAddress =
  network.name === "polygon_mumbai"
    ? proxies["polygon_mumbai" as keyof TablelandNetworkConfig]
    : proxies[network.name as keyof TablelandNetworkConfig];
// Get the baseURI with only the endpoint `/api/v1/` instead of an appended `/tables`
let baseURI =
  network.name === "polygon_mumbai"
    ? baseURIs["polygon_mumbai" as keyof TablelandNetworkConfig]
    : baseURIs[network.name as keyof TablelandNetworkConfig];
baseURI = baseURI.match(/^https?:\/\/[^\/]+\/[^\/]+\/[^\/]+\/?/)![0];

if (!registryAddress)
  throw new Error("cannot get registry address for " + network.name);
if (!baseURI) throw new Error("cannot get base URI for " + network.name);

  // Deploy EventFactory
  const EventFactory = await hre.ethers.getContractFactory("EventFactory");
  const eventFactory = await EventFactory.deploy("base_uri", "external_uri");
  await eventFactory.deployed();
  console.log(`Lock deployed to ${eventFactory.address}`);
  const [signer] = await hre.ethers.getSigners();
  const chainId = await signer.getChainId();
  // const db = new Database({
  //   signer,
  //   baseUrl: helpers.getBaseUrl(chainId),
  // });
  // const validator = new Validator(db.config);
  // const name = await validator.getTableById(tableId);
  // const data = await db.prepare(`SELECT * from ${name}`).all();
  console.log(`Data in table '${name}':`);
  // console.log(data);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
