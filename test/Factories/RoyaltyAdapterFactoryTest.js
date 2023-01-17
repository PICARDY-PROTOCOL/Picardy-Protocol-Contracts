const { assert, expect } = require("chai");
const chai = require("chai");
const { ethers } = require("hardhat");
chai.use(require("chai-as-promised"));

describe("RoyaltyAdapterFactory", function () {
  let picardyHub;
  let royaltyAdapterFactory;
  let nftRoyaltyAdapterImp;
  let tokenRoyaltyAdapterImp;

  const maxSupply = 100;
  const maxMintAmount = 20;
  const formatedCost = ethers.utils.parseUnits("1", "ether"); // 1 eth
  const percentage = 10;
  const name = "testToken";
  const symbol = "TST";
  const initBaseURI = "https://test.com/";
  const creatorName = "testArtiste";

  const askAmount = ethers.utils.parseUnits("100", "ether");
  const returnPercentage = 20;
  const creatorsName = "testCreator";

  let linkToken;
  let jobId = "42b90f5bf8b940029fed6330f7036f01";
  let oracleAddress = "0x7E0ffaca8352CbB93c099C08b9aD7B4bE9f790Ec";
  let nftRoyaltyImpAddress;
  let tokenRoyaltyImpAddress;
  let nftRoyaltySaleFactory;
  let nftRoyaltySaleAddress;
  let tokenRoyaltyFactory;
  let tokenRoyaltySaleAddress;
  let payMaster;

  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    let details = {
      maxSupply: maxSupply,
      maxMintAmount: maxMintAmount,
      cost: formatedCost,
      percentage: percentage,
      name: name,
      symbol: symbol,
      initBaseURI: initBaseURI,
      creatorName: creatorName,
      creator: user1.address,
    };

    const LinkToken = await ethers.getContractFactory("MocLink");
    tokenContract = await LinkToken.deploy();
    linkToken = tokenContract.address;

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const PayMaster = await ethers.getContractFactory("PayMaster");
    payMaster = await PayMaster.deploy(picardyHub.address);

    const NftRoyaltySaleImpl = await hre.ethers.getContractFactory(
      "NftRoyaltySale"
    );

    const nftRoyaltyImp = await NftRoyaltySaleImpl.deploy();
    await nftRoyaltyImp.deployed();
    nftRoyaltyImpAddress = nftRoyaltyImp.address;

    const NftRoyaltySaleFactory = await ethers.getContractFactory(
      "NftRoyaltySaleFactory"
    );

    nftRoyaltySaleFactory = await NftRoyaltySaleFactory.deploy(
      picardyHub.address,
      linkToken,
      nftRoyaltyImpAddress
    );

    const TokenRoyaltySaleFactory = await ethers.getContractFactory(
      "TokenRoyaltySaleFactory"
    );

    const TokenRoyaltySaleImpl = await hre.ethers.getContractFactory(
      "TokenRoyaltySale"
    );

    const tokenRoyaltyImp = await TokenRoyaltySaleImpl.deploy();
    await tokenRoyaltyImp.deployed();
    tokenRoyaltyImpAddress = tokenRoyaltyImp.address;

    tokenRoyaltyFactory = await TokenRoyaltySaleFactory.deploy(
      picardyHub.address,
      linkToken,
      tokenRoyaltyImpAddress
    );

    const tx1 = await nftRoyaltySaleFactory
      .connect(user1)
      .createNftRoyalty(details);

    nftRoyaltySaleAddress =
      await nftRoyaltySaleFactory.getNftRoyaltySaleAddress(creatorName, name);

    const tx2 = await tokenRoyaltyFactory
      .connect(user1)
      .createTokenRoyalty(
        askAmount,
        returnPercentage,
        creatorsName,
        name,
        user1.address
      );

    tokenRoyaltySaleAddress = await tokenRoyaltyFactory
      .connect(user1)
      .getTokenRoyaltyAddress(creatorsName, name);

    const NftRoyaltyAdapterImp = await hre.ethers.getContractFactory(
      "RoyaltyAdapter"
    );
    nftRoyaltyAdapterImp = await NftRoyaltyAdapterImp.deploy();

    const TokenRoyaltyAdapterImp = await hre.ethers.getContractFactory(
      "TokenRoyaltyAdapter"
    );

    tokenRoyaltyAdapterImp = await TokenRoyaltyAdapterImp.deploy();

    const RoyaltyAdapterFactory = await hre.ethers.getContractFactory(
      "RoyaltyAdapterFactory"
    );
    royaltyAdapterFactory = await RoyaltyAdapterFactory.deploy(
      picardyHub.address,
      linkToken,
      oracleAddress,
      jobId,
      await nftRoyaltyAdapterImp.address,
      await tokenRoyaltyAdapterImp.address,
      payMaster.address
    );
  });

  it("user can create royalty adapter", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    let ticker = "ETH";

    await expect(
      royaltyAdapterFactory
        .connect(user1)
        .createAdapter(royaltyAddress.address, 0, ticker)
    ).to.be.rejectedWith(Error);

    const nftRoyaltyAdapter = await royaltyAdapterFactory
      .connect(user1)
      .createAdapter(nftRoyaltySaleAddress, 0, ticker);

    const nftRoyaltyReceipt = await nftRoyaltyAdapter.wait();

    const res = await royaltyAdapterFactory
      .connect(user1)
      .getAdapterDetails(nftRoyaltySaleAddress);

    const events1 = [];
    for (let item of nftRoyaltyReceipt.events) {
      events1.push(item.event);
    }
    expect(events1).to.include("AdapterCreated");
    assert.equal(
      await nftRoyaltyReceipt.events[0].args.adapterAddress,
      res.adapterAddress
    );
    assert.equal(await nftRoyaltyReceipt.events[0].args.adapterId, 1);

    const tokenRoyaltyAdapter = await royaltyAdapterFactory
      .connect(user1)
      .createAdapter(tokenRoyaltySaleAddress, 1, ticker);

    const tokenRoyaltyReceipt = await tokenRoyaltyAdapter.wait();

    const res2 = await royaltyAdapterFactory
      .connect(user1)
      .getAdapterDetails(tokenRoyaltySaleAddress);

    const events2 = [];
    for (let item of tokenRoyaltyReceipt.events) {
      events2.push(item.event);
    }
    expect(events2).to.include("AdapterCreated");
    assert.equal(
      await tokenRoyaltyReceipt.events[0].args.adapterAddress,
      res2.adapterAddress
    );
    assert.equal(await tokenRoyaltyReceipt.events[0].args.adapterId, 2);
  });

  it("only hub admin can update factroy details", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      royaltyAdapterFactory.connect(user1).changeOracle(oracleAddress)
    ).to.be.rejectedWith(Error);

    await expect(
      royaltyAdapterFactory.connect(user1).changeLinkToken(linkToken)
    ).to.be.rejectedWith(Error);

    await expect(
      royaltyAdapterFactory.connect(user1).changeJobId(jobId)
    ).to.be.rejectedWith(Error);

    await royaltyAdapterFactory.connect(hubAdmin).changeJobId(jobId);

    await royaltyAdapterFactory.connect(hubAdmin).changeOracle(oracleAddress);

    await royaltyAdapterFactory.connect(hubAdmin).changeLinkToken(linkToken);
  });
});
