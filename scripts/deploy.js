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
  //Import comtracts
  const PicardyHub = await hre.ethers.getContractFactory("PicardyHub");
  const PicardyVaultFactory = await hre.ethers.getContractFactory(
    "PicardyVaultFactory"
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
  const CrowdfundFactory = await hre.ethers.getContractFactory(
    "CrowdfundFactory"
  );
  const RoyaltyAdapterFactory = await hre.ethers.getContractFactory(
    "RoyaltyAdapterFactory"
  );
  const DaoFactory = await hre.ethers.getContractFactory("DaoFactory");
  const TimelockFactory = await hre.ethers.getContractFactory(
    "TimelockFactory"
  );

  //Deploy contracts

  const picardyHub = await PicardyHub.deploy();
  await picardyHub.deployed();
  const picardyHubAddress = picardyHub.address;

  const picardyVaultFactory = await PicardyVaultFactory.deploy(
    picardyHubAddress
  );
  await picardyVaultFactory.deployed();
  const picardyVaultFactoryAddress = picardyVaultFactory.address;

  const artisteTokenFactory = await ArtisteTokenFactory.deploy(
    picardyHubAddress
  );
  await artisteTokenFactory.deployed();
  const artisteTokenFactoryAddress = artisteTokenFactory.address;

  const nftRoyaltySaleFactory = await NftRoyaltySaleFactory.deploy(
    picardyHubAddress,
    linkToken
  );
  await nftRoyaltySaleFactory.deployed();
  const nftRoyaltySaleFactoryAddress = nftRoyaltySaleFactory.address;

  const tokenRoyaltySaleFactory = await TokenRoyaltySaleFactory.deploy(
    picardyHubAddress,
    linkToken
  );
  await tokenRoyaltySaleFactory.deployed();
  const tokenRoyaltySaleFactoryAddress = tokenRoyaltySaleFactory.address;

  const crowdfundFactory = await CrowdfundFactory.deploy(picardyHubAddress);
  await crowdfundFactory.deployed();
  const crowdfundFactoryAddress = crowdfundFactory.address;

  const royaltyAdapterFactory = await RoyaltyAdapterFactory.deploy(
    picardyHubAddress,
    linkToken,
    oracleAddress,
    jobId
  );
  await royaltyAdapterFactory.deployed();
  const royaltyAdapterFactoryAddress = royaltyAdapterFactory.address;

  const daoFactory = await DaoFactory.deploy(picardyHubAddress);
  await daoFactory.deployed();
  const daoFactoryAddress = daoFactory.address;

  const timelockFactory = await TimelockFactory.deploy(picardyHubAddress);
  await timelockFactory.deployed();
  const timelockFactoryAddress = timelockFactory.address;

  //Init dao factory and timelock factory

  await daoFactory.addTimelockFactoryAddress(timelockFactoryAddress);
  await timelockFactory.addDaoFactoryAddress(daoFactoryAddress);

  // log Addresses

  const deployedAddress = {
    picardyHub: picardyHubAddress,
    picardyVaultFactory: picardyVaultFactoryAddress,
    artisteTokenFactory: artisteTokenFactoryAddress,
    nftRoyaltySaleFactory: nftRoyaltySaleFactoryAddress,
    tokenRoyaltySaleFactory: tokenRoyaltySaleFactoryAddress,
    crowdfundFactory: crowdfundFactoryAddress,
    daoFactory: daoFactoryAddress,
    timelockFactory: timelockFactoryAddress,
    royaltyAdapterFactory: royaltyAdapterFactoryAddress,
  };

  addresses = JSON.stringify(deployedAddress);
  writeAddress(addresses);

  console.table({
    picardyHub: picardyHubAddress,
    picardyVaultFactory: picardyVaultFactoryAddress,
    artisteTokenFactory: artisteTokenFactoryAddress,
    nftRoyaltySaleFactory: nftRoyaltySaleFactoryAddress,
    tokenRoyaltySaleFactory: tokenRoyaltySaleFactoryAddress,
    crowdfundFactory: crowdfundFactoryAddress,
    daoFactory: daoFactoryAddress,
    timelockFactory: timelockFactoryAddress,
    royaltyAdapterFactory: royaltyAdapterFactoryAddress,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
