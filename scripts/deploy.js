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
  const jobId = "42b90f5bf8b940029fed6330f7036f01";
  const oracleAddress = "0x7E0ffaca8352CbB93c099C08b9aD7B4bE9f790Ec";
  const registry = "";
  const registrar = "";
  //Import comtracts
  const PicardyHub = await hre.ethers.getContractFactory("PicardyHub");

  const RoyaltyAdapterFactory = await hre.ethers.getContractFactory(
    "RoyaltyAdapterFactory"
  );

  const PayMaster = await hre.ethers.getContractFactory("PayMaster");

  const RoyaltyAutomationRegistrar = await hre.ethers.getContractFactory(
    "RoyaltyAutomationRegistrar"
  );

  const NftRoyaltyAdapterImp = await hre.ethers.getContractFactory(
    "RoyaltyAdapter"
  );

  const TokenRoyaltyAdapterImp = await hre.ethers.getContractFactory(
    "TokenRoyaltyAdapter"
  );

  const NftRoyaltySaleImpl = await hre.ethers.getContractFactory(
    "NftRoyaltySale"
  );

  const TokenRoyaltySaleImpl = await hre.ethers.getContractFactory(
    "TokenRoyaltySale"
  );

  const ArtisteTokenFactory = await hre.ethers.getContractFactory(
    "ArtisteTokenFactory"
  );
  const NftRoyaltySaleFactory = await hre.ethers.getContractFactory(
    "NftRoyaltySaleFactory"
  );
  const TokenRoyaltySaleFactory = await hre.ethers.getContractFactory(
    "TokenRoyaltySaleFactory"
  );

  //Deploy Implimentation contracts

  const nftRoyaltyImp = await NftRoyaltySaleImpl.deploy();
  await nftRoyaltyImp.deployed();
  const nftRoyaltyImpAddress = nftRoyaltyImp.address;

  const tokenRoyaltyImp = await TokenRoyaltySaleImpl.deploy();
  await tokenRoyaltyImp.deployed();
  const tokenRoyaltyImpAddress = tokenRoyaltyImp.address;

  const nftRoyaltyAdapterImp = await NftRoyaltyAdapterImp.deploy();
  await nftRoyaltyAdapterImp.deployed();
  const nftRoyaltyAdapterImpAddr = nftRoyaltyAdapterImp.address;

  const tokenRoyaltyAdapterImp = await TokenRoyaltyAdapterImp.deploy();
  await tokenRoyaltyAdapterImp.deployed();
  const tokenRoyaltyAdapterImpAddr = tokenRoyaltyAdapterImp.address;

  //Deploy contracts

  const picardyHub = await PicardyHub.deploy();
  await picardyHub.deployed();
  const picardyHubAddress = picardyHub.address;

  const payMaster = await PayMaster.deploy(picardyHubAddress);
  await payMaster.deployed();
  const payMasterAddress = payMaster.address;

  const royaltyAdapterFactory = await RoyaltyAdapterFactory.deploy(
    picardyHubAddress,
    linkToken,
    oracleAddress,
    jobId,
    nftRoyaltyAdapterImpAddr,
    tokenRoyaltyAdapterImpAddr
  );
  await royaltyAdapterFactory.deployed();
  const royaltyAdapterFactoryAddress = royaltyAdapterFactory.address;

  const royaltyAutomationRegistrar = await RoyaltyAutomationRegistrar.deploy(
    linkToken,
    registrar,
    registry,
    royaltyAdapterFactoryAddress,
    picardyHubAddress,
    payMasterAddress
  );
  await royaltyAutomationRegistrar.deployed();
  const royaltyAutomationRegistrarAddress = royaltyAutomationRegistrar.address;

  //Initilize the royaltyAutomationRegistrar in paymaster and Royalty adapter factory
  await payMaster.addRegAddress(royaltyAutomationRegistrarAddress);
  await royaltyAdapterFactory.addPicardyReg(royaltyAutomationRegistrarAddress);

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
    royaltyAdapterFactory: royaltyAdapterFactoryAddress,
    payMasterAddress: payMasterAddress,
    automationRegistrarAddress: royaltyAutomationRegistrarAddress,

    implimentations: {
      nftRoyaltySale: nftRoyaltyAdapterImpAddr,
      tokenRoyaltySale: tokenRoyaltyAdapterImpAddr,
      nftRoyaltyAdapter: nftRoyaltyAdapterImpAddr,
      tokenRoyaltyAdapter: tokenRoyaltyAdapterImpAddr,
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
    royaltyAdapterFactory: royaltyAdapterFactoryAddress,
    nftRoyaltySaleImp: nftRoyaltyAdapterImpAddr,
    tokenRoyaltySaleImp: tokenRoyaltyAdapterImpAddr,
    nftRoyaltyAdapterImp: nftRoyaltyAdapterImpAddr,
    tokenRoyaltyAdapterImp: tokenRoyaltyAdapterImpAddr,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
