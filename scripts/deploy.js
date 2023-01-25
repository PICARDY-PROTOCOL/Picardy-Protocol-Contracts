const hre = require("hardhat");
const { existsSync, mkdirSync, writeFileSync } = require("fs");
//const { json } = require("hardhat/internal/core/params/argumentTypes");

const writeAddress = (addresses) => {
  const path = "./Deployed_address/address.json";

  if (!existsSync("./Deployed_address")) {
    mkdirSync("./Deployed_address");
  }
  writeFileSync(path, addresses, (err) => {
    console.log(err);
  });
  console.log(`address coppied to ${path}`);
};

async function main() {
  let addresses;
  // change for testnet and mainnet deployment,
  const linkToken = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
  const registry = "0x02777053d6764996e594c3E88AF1D58D5363a2e6"; // change this for testnet or mainnet deployment
  const registrar = "0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d"; // change this for testnet or mainnet deployment
  //Import comtracts
  const PicardyHub = await hre.ethers.getContractFactory("PicardyHub");

  const PayMaster = await hre.ethers.getContractFactory("PayMasterV2");

  const RoyaltyAutomationRegistrar = await hre.ethers.getContractFactory(
    "RoyaltyAutomationRegistrarV2"
  );

  const RoyaltyAdapter = await hre.ethers.getContractFactory(
    "RoyaltyAdapterV2"
  );

  const NftRoyaltySaleImpl = await hre.ethers.getContractFactory(
    "NftRoyaltySaleV2"
  );

  const TokenRoyaltySaleImpl = await hre.ethers.getContractFactory(
    "TokenRoyaltySaleV2"
  );

  const ArtisteTokenFactory = await hre.ethers.getContractFactory(
    "ArtisteTokenFactory"
  );
  const NftRoyaltySaleFactory = await hre.ethers.getContractFactory(
    "NftRoyaltySaleFactoryV2"
  );
  const TokenRoyaltySaleFactory = await hre.ethers.getContractFactory(
    "TokenRoyaltySaleFactoryV2"
  );

  //Deploy Implimentation contracts

  const nftRoyaltyImp = await NftRoyaltySaleImpl.deploy();
  await nftRoyaltyImp.deployed();
  const nftRoyaltyImpAddress = nftRoyaltyImp.address;

  const tokenRoyaltyImp = await TokenRoyaltySaleImpl.deploy();
  await tokenRoyaltyImp.deployed();
  const tokenRoyaltyImpAddress = tokenRoyaltyImp.address;

  //Deploy contracts

  const picardyHub = await PicardyHub.deploy();
  await picardyHub.deployed();
  const picardyHubAddress = picardyHub.address;

  const payMaster = await PayMaster.deploy(picardyHubAddress);
  await payMaster.deployed();
  const payMasterAddress = payMaster.address;

  const royaltyAdapter = await RoyaltyAdapter.deploy(
    linkToken,
    payMasterAddress,
    picardyHubAddress
  );
  await royaltyAdapter.deployed();
  const royaltyAdapterAddress = royaltyAdapter.address;

  const royaltyAutomationRegistrar = await RoyaltyAutomationRegistrar.deploy(
    linkToken,
    registrar,
    registry,
    royaltyAdapterAddress,
    picardyHubAddress,
    payMasterAddress
  );
  await royaltyAutomationRegistrar.deployed();
  const royaltyAutomationRegistrarAddress = royaltyAutomationRegistrar.address;

  //Initilize the royaltyAutomationRegistrar in paymaster and Royalty adapter
  await payMaster.addRegAddress(royaltyAutomationRegistrarAddress);
  await royaltyAdapter.addPicardyReg(royaltyAutomationRegistrarAddress);

  // Deploy Product Factory

  const artisteTokenFactory = await ArtisteTokenFactory.deploy(
    picardyHubAddress
  );
  await artisteTokenFactory.deployed();
  const artisteTokenFactoryAddress = artisteTokenFactory.address;

  const nftRoyaltySaleFactory = await NftRoyaltySaleFactory.deploy(
    picardyHubAddress,
    linkToken,
    nftRoyaltyImpAddress
  );
  await nftRoyaltySaleFactory.deployed();
  const nftRoyaltySaleFactoryAddress = nftRoyaltySaleFactory.address;

  const tokenRoyaltySaleFactory = await TokenRoyaltySaleFactory.deploy(
    picardyHubAddress,
    linkToken,
    tokenRoyaltyImpAddress
  );
  await tokenRoyaltySaleFactory.deployed();
  const tokenRoyaltySaleFactoryAddress = tokenRoyaltySaleFactory.address;

  // log Addresses

  const deployedAddress = {
    picardyHub: picardyHubAddress,
    artisteTokenFactory: artisteTokenFactoryAddress,
    nftRoyaltySaleFactory: nftRoyaltySaleFactoryAddress,
    tokenRoyaltySaleFactory: tokenRoyaltySaleFactoryAddress,
    royaltyAdapter: royaltyAdapterAddress,
    payMasterAddress: payMasterAddress,
    automationRegistrarAddress: royaltyAutomationRegistrarAddress,

    implimentations: {
      nftRoyaltySale: nftRoyaltyImpAddress,
      tokenRoyaltySale: tokenRoyaltyImpAddress,
    },
  };

  addresses = JSON.stringify(deployedAddress);
  writeAddress(addresses);

  console.table({
    picardyHub: picardyHubAddress,
    payMasterAddress: payMasterAddress,
    automationRegistrarAddress: royaltyAutomationRegistrarAddress,
    artisteTokenFactory: artisteTokenFactoryAddress,
    nftRoyaltySaleFactory: nftRoyaltySaleFactoryAddress,
    tokenRoyaltySaleFactory: tokenRoyaltySaleFactoryAddress,
    royaltyAdapter: royaltyAdapterAddress,
    nftRoyaltySaleImp: nftRoyaltyImpAddress,
    tokenRoyaltySaleImp: tokenRoyaltyImpAddress,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
