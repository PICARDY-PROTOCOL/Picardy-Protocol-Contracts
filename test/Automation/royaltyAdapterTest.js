const { assert, expect } = require("chai");
const chai = require("chai");
const { ethers } = require("hardhat");
chai.use(require("chai-as-promised"));

describe("nftRoyaltyAdapter", function () {
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
  const creatorName = "creator";

  let linkToken;
  let jobId = "42b90f5bf8b940029fed6330f7036f01";
  let oracleAddress = "0x7E0ffaca8352CbB93c099C08b9aD7B4bE9f790Ec";
  let nftRoyaltyImpAddress;
  let nftRoyaltySaleFactory;
  let nftRoyaltySaleAddress;
  let nftRoyaltyAdapter;
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

    let ticker = "ETH";

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

    const tx1 = await nftRoyaltySaleFactory
      .connect(user1)
      .createNftRoyalty(details);

    nftRoyaltySaleAddress =
      await nftRoyaltySaleFactory.getNftRoyaltySaleAddress(creatorName, name);

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

    const tx = await royaltyAdapterFactory
      .connect(user1)
      .createAdapter(nftRoyaltySaleAddress, 0, ticker);

    const receipt = await tx.wait();

    const res = await royaltyAdapterFactory
      .connect(user1)
      .getAdapterDetails(nftRoyaltySaleAddress);

    nftRoyaltyAdapter = await ethers.getContractAt(
      "RoyaltyAdapter",
      res.adapterAddress,
      user1
    );

    await tokenContract.mint(
      ethers.utils.parseUnits("100", "ether"),
      nftRoyaltyAdapter.address
    );
  });

  it("only owner can initilize adapter", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      nftRoyaltyAdapter.connect(user2).initilizeAdapter(oracleAddress, jobId)
    ).to.be.rejectedWith(Error);

    await nftRoyaltyAdapter
      .connect(user1)
      .initilizeAdapter(oracleAddress, jobId);
  });

  it("only owner should withdraw link", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      nftRoyaltyAdapter.connect(user2).withdrawLink()
    ).to.be.rejectedWith(Error);

    const linkBalance = await tokenContract.balanceOf(
      nftRoyaltyAdapter.address
    );

    await nftRoyaltyAdapter.connect(user1).withdrawLink();

    const ownersLinkBalance = await tokenContract.balanceOf(user1.address);

    expect(ownersLinkBalance).to.equal(linkBalance);
  });

  it("only owner should withdraw eth", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      nftRoyaltyAdapter.connect(user2).withdrawBalance()
    ).to.be.rejectedWith(Error);

    await user2.sendTransaction({
      to: nftRoyaltyAdapter.address,
      value: ethers.utils.parseUnits("50", "ether"),
    });

    await nftRoyaltyAdapter.connect(user1).withdrawBalance();
  });
}); // end describe

describe("TokenRoyaltyAdapter", function () {
  let picardyHub;
  let royaltyAdapterFactory;
  let tokenRoyaltyAdapterImp;

  const askAmount = ethers.utils.parseUnits("100", "ether");
  const returnPercentage = 20;
  const creatorsName = "testCreator";
  const name = "testToken";

  let linkToken;
  let jobId = "42b90f5bf8b940029fed6330f7036f01";
  let oracleAddress = "0x7E0ffaca8352CbB93c099C08b9aD7B4bE9f790Ec";
  let tokenRoyaltyImpAddress;
  let tokenRoyaltyFactory;
  let tokenRoyaltySaleAddress;
  let nftRoyaltyAdapterImp;
  let tokenRoyaltyAdapter;
  let payMaster;

  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    let ticker = "ETH";

    const LinkToken = await ethers.getContractFactory("MocLink");
    tokenContract = await LinkToken.deploy();
    linkToken = tokenContract.address;

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const PayMaster = await ethers.getContractFactory("PayMaster");
    payMaster = await PayMaster.deploy(picardyHub.address);

    const TokenRoyaltySaleImpl = await hre.ethers.getContractFactory(
      "TokenRoyaltySale"
    );

    const TokenRoyaltySaleFactory = await ethers.getContractFactory(
      "TokenRoyaltySaleFactory"
    );

    const tokenRoyaltyImp = await TokenRoyaltySaleImpl.deploy();
    await tokenRoyaltyImp.deployed();
    tokenRoyaltyImpAddress = tokenRoyaltyImp.address;

    tokenRoyaltyFactory = await TokenRoyaltySaleFactory.deploy(
      picardyHub.address,
      linkToken,
      tokenRoyaltyImpAddress
    );

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

    const tx = await royaltyAdapterFactory
      .connect(user1)
      .createAdapter(tokenRoyaltySaleAddress, 1, ticker);

    const receipt = await tx.wait();

    const res = await royaltyAdapterFactory
      .connect(user1)
      .getAdapterDetails(tokenRoyaltySaleAddress);

    tokenRoyaltyAdapter = await ethers.getContractAt(
      "TokenRoyaltyAdapter",
      res.adapterAddress,
      user1
    );

    await tokenContract.mint(
      ethers.utils.parseUnits("100", "ether"),
      tokenRoyaltyAdapter.address
    );
  });

  it("only owner can initilize adapter", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      tokenRoyaltyAdapter.connect(user2).initilizeAdapter(oracleAddress, jobId)
    ).to.be.rejectedWith(Error);

    await tokenRoyaltyAdapter
      .connect(user1)
      .initilizeAdapter(oracleAddress, jobId);
  });

  it("only owner should withdraw link", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      tokenRoyaltyAdapter.connect(user2).withdrawLink()
    ).to.be.rejectedWith(Error);

    const linkBalance = await tokenContract.balanceOf(
      tokenRoyaltyAdapter.address
    );

    await tokenRoyaltyAdapter.connect(user1).withdrawLink();

    const ownersLinkBalance = await tokenContract.balanceOf(user1.address);

    expect(ownersLinkBalance).to.equal(linkBalance);
  });

  it("only owner should withdraw eth", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      tokenRoyaltyAdapter.connect(user2).withdrawBalance()
    ).to.be.rejectedWith(Error);

    await user2.sendTransaction({
      to: tokenRoyaltyAdapter.address,
      value: ethers.utils.parseUnits("50", "ether"),
    });

    await tokenRoyaltyAdapter.connect(user1).withdrawBalance();
  });
}); // end describe
