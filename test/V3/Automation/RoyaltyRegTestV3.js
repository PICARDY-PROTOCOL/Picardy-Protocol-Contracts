const { assert, expect } = require("chai");
const chai = require("chai");
const { ethers } = require("hardhat");
chai.use(require("chai-as-promised"));

describe("RoyaltyRegTestV3", function () {
  let royaltyAutomationRegistrar;
  let payMaster;
  let tokenRoyaltySaleFactory;
  let picardyHub;
  let nftRoyaltySaleFactory;
  let nftRoyaltyImp;
  let tokenRoyaltyImp;
  let royaltyAdapter;
  let linkToken;
  let nftRoyaltySaleAddress;
  let nftRoyaltySale;
  let tokenRoyaltySale;
  let tokenRoyaltySaleAddress;

  let jobId = "42b90f5bf8b940029fed6330f7036f01";
  let oracleAddress = "0x7E0ffaca8352CbB93c099C08b9aD7B4bE9f790Ec";
  let ticker = "ETH";

  const maxSupply = 100;
  const maxMintAmount = 10;
  const cost = ethers.utils.parseUnits("1", "ether"); // 1 eth
  const percentage = 10;
  const name = "testToken";
  const symbol = "TST";
  const initBaseURI = "https://test.com/";
  const creatorName = "testArtiste";

  const mintAmount = 2;
  let total = 1 * mintAmount;

  const formattedTotal = ethers.utils.parseUnits(total.toString(), "ether");

  beforeEach(async () => {
    const [hubAdmin, user1, user2, user3, royaltyAddress] =
      await ethers.getSigners();

    const LinkToken = await ethers.getContractFactory("MocLink");
    linkToken = await LinkToken.deploy();

    const RoyaltyAutomationRegistrar = await ethers.getContractFactory(
      "RoyaltyAutomationRegistrarV3"
    );

    const PicardyHub = await ethers.getContractFactory("PicardyHub");

    const PayMaster = await ethers.getContractFactory("PayMasterV3");

    const NftRoyaltySaleImpl = await ethers.getContractFactory(
      "NftRoyaltySaleV3"
    );

    const TokenRoyaltySaleImpl = await ethers.getContractFactory(
      "TokenRoyaltySaleV3"
    );

    const TokenRoyaltySaleFactory = await ethers.getContractFactory(
      "TokenRoyaltySaleFactoryV3"
    );

    const NftRoyaltySaleFactory = await ethers.getContractFactory(
      "NftRoyaltySaleFactoryV3"
    );

    const RoyaltyAdapterV3 = await ethers.getContractFactory(
      "RoyaltyAdapterV3"
    );

    //DEPLOY CONTRACTS
    //Deploy Implimentation contracts

    nftRoyaltyImp = await NftRoyaltySaleImpl.deploy();
    await nftRoyaltyImp.deployed();
    const nftRoyaltyImpAddress = nftRoyaltyImp.address;

    tokenRoyaltyImp = await TokenRoyaltySaleImpl.deploy();
    await tokenRoyaltyImp.deployed();
    const tokenRoyaltyImpAddress = tokenRoyaltyImp.address;

    //Deploy contracts

    picardyHub = await PicardyHub.deploy();
    await picardyHub.deployed();
    const picardyHubAddress = picardyHub.address;

    payMaster = await PayMaster.deploy(picardyHubAddress);
    await payMaster.deployed();
    const payMasterAddress = payMaster.address;

    royaltyAdapter = await RoyaltyAdapterV3.deploy(
      linkToken.address,
      payMasterAddress,
      picardyHubAddress
    );
    await royaltyAdapter.deployed();
    const royaltyAdapterAddress = royaltyAdapter.address;

    royaltyAutomationRegistrar = await RoyaltyAutomationRegistrar.deploy(
      linkToken.address,
      royaltyAdapterAddress,
      picardyHubAddress,
      payMasterAddress
    );
    await royaltyAutomationRegistrar.deployed();
    const royaltyAutomationRegistrarAddress =
      royaltyAutomationRegistrar.address;

    //Initilize the royaltyAutomationRegistrar in paymaster and Royalty adapter
    await payMaster.addRegAddress(royaltyAutomationRegistrarAddress);
    await royaltyAdapter.addPicardyReg(royaltyAutomationRegistrarAddress);

    // Deploy Product Factory contracts

    nftRoyaltySaleFactory = await NftRoyaltySaleFactory.deploy(
      picardyHubAddress,
      linkToken.address,
      nftRoyaltyImpAddress
    );
    await nftRoyaltySaleFactory.deployed();

    tokenRoyaltySaleFactory = await TokenRoyaltySaleFactory.deploy(
      picardyHubAddress,
      linkToken.address,
      tokenRoyaltyImpAddress
    );
    await tokenRoyaltySaleFactory.deployed();

    //Initilize a sale case to test automation witt

    let details = {
      maxSupply: maxSupply,
      maxMintAmount: maxMintAmount,
      cost: cost,
      percentage: percentage,
      name: name,
      symbol: symbol,
      initBaseURI: initBaseURI,
      creatorName: creatorName,
      creator: user1.address,
    };

    await nftRoyaltySaleFactory.connect(user1).createNftRoyalty(details);
    nftRoyaltySaleAddress = await nftRoyaltySaleFactory
      .connect(user1)
      .getNftRoyaltySaleAddress(creatorName, name);

    nftRoyaltySale = await ethers.getContractAt(
      "NftRoyaltySaleV3",
      nftRoyaltySaleAddress,
      user1
    );
    nftRoyaltySale.connect(user1).start();

    await tokenRoyaltySaleFactory
      .connect(user2)
      .createTokenRoyalty(
        ethers.utils.parseUnits("100", "ether"),
        percentage,
        creatorName,
        "testToken",
        user2.address,
        symbol
      );

    tokenRoyaltySaleAddress =
      await tokenRoyaltySaleFactory.getTokenRoyaltyAddress(creatorName, name);

    tokenRoyaltySale = await ethers.getContractAt(
      "TokenRoyaltySaleV3",
      tokenRoyaltySaleAddress,
      user1
    );

    tokenRoyaltySale.connect(user2).start();
    await tokenRoyaltySale.connect(user1).buyRoyalty(user1.address, {
      value: formattedTotal,
    });

    await tokenRoyaltySale.connect(user3).buyRoyalty(user3.address, {
      value: formattedTotal,
    });

    await nftRoyaltySale
      .connect(user2)
      .buyRoyalty(2, user2.address, { value: formattedTotal });

    await nftRoyaltySale
      .connect(user3)
      .buyRoyalty(2, user3.address, { value: formattedTotal });

    nftRoyaltySale.connect(user1).endRoyaltySale();
    tokenRoyaltySale.connect(user2).endRoyaltySale();
  });

  it("only NFT royalty Admain should register automation", async () => {
    const [hubAdmin, user1, user2, user3, royaltyAddress] =
      await ethers.getSigners();

    let registrationDetails = {
      ticker: "ETH",
      jobId: jobId,
      oracle: oracleAddress,
      royaltyAddress: nftRoyaltySale.address,
      adminAddress: user1.address,
      royaltyType: 0,
      updateInterval: 4,
      amount: ethers.utils.parseUnits("10", "ether"),
    };

    await expect(
      royaltyAutomationRegistrar.connect(user2).register(registrationDetails)
    ).to.be.rejectedWith(Error);

    await linkToken.mint(20, user1.address);
    await linkToken
      .connect(user1)
      .approve(
        royaltyAutomationRegistrar.address,
        ethers.utils.parseUnits("20", "ether")
      );
    console.log("user1 balance", await linkToken.balanceOf(user1.address));
    await royaltyAutomationRegistrar
      .connect(user1)
      .register(registrationDetails);

    console.log(
      "royaltyLinkBalance",
      await royaltyAdapter.getRoyaltyLinkBalance(nftRoyaltySale.address)
    );
  });

  it("only NFT royalty admin can toggle automation", async () => {
    const [hubAdmin, user1, user2, user3, royaltyAddress] =
      await ethers.getSigners();

    let registrationDetails = {
      ticker: "ETH",
      jobId: jobId,
      oracle: oracleAddress,
      royaltyAddress: nftRoyaltySale.address,
      adminAddress: user1.address,
      royaltyType: 0,
      updateInterval: 4,
      amount: ethers.utils.parseUnits("10", "ether"),
    };

    await linkToken.mint(20, user1.address);
    await linkToken
      .connect(user1)
      .approve(
        royaltyAutomationRegistrar.address,
        ethers.utils.parseUnits("20", "ether")
      );
    await royaltyAutomationRegistrar
      .connect(user1)
      .register(registrationDetails);

    await expect(
      royaltyAutomationRegistrar
        .connect(user2)
        .toggleAutomation(nftRoyaltySale.address)
    ).to.be.rejectedWith(Error);

    await royaltyAutomationRegistrar
      .connect(user1)
      .toggleAutomation(nftRoyaltySale.address);
  });

  it("Only NFT royalty admin should cancleAutomation", async () => {
    const [hubAdmin, user1, user2, user3, royaltyAddress] =
      await ethers.getSigners();

    let registrationDetails = {
      ticker: "ETH",
      jobId: jobId,
      oracle: oracleAddress,
      royaltyAddress: nftRoyaltySale.address,
      adminAddress: user1.address,
      royaltyType: 0,
      updateInterval: 4,
      amount: ethers.utils.parseUnits("10", "ether"),
    };

    await linkToken.mint(20, user1.address);
    await linkToken
      .connect(user1)
      .approve(
        royaltyAutomationRegistrar.address,
        ethers.utils.parseUnits("20", "ether")
      );
    await royaltyAutomationRegistrar
      .connect(user1)
      .register(registrationDetails);

    await expect(
      royaltyAutomationRegistrar
        .connect(user2)
        .cancelAutomation(nftRoyaltySale.address)
    ).to.be.rejectedWith(Error);

    await royaltyAutomationRegistrar
      .connect(user1)
      .cancelAutomation(nftRoyaltySale.address);
  });

  it("only token royalty Admain should register automation", async () => {
    const [hubAdmin, user1, user2, user3, royaltyAddress] =
      await ethers.getSigners();

    let registrationDetails = {
      ticker: "ETH",
      jobId: jobId,
      oracle: oracleAddress,
      royaltyAddress: tokenRoyaltySale.address,
      adminAddress: user2.address,
      royaltyType: 1,
      updateInterval: 4,
      amount: ethers.utils.parseUnits("10", "ether"),
    };

    await expect(
      royaltyAutomationRegistrar.connect(user2).register(registrationDetails)
    ).to.be.rejectedWith(Error);

    await linkToken.mint(ethers.utils.parseUnits("20", "ether"), user2.address);
    await linkToken
      .connect(user2)
      .approve(
        royaltyAutomationRegistrar.address,
        ethers.utils.parseUnits("20", "ether")
      );
    console.log("user2 balance", await linkToken.balanceOf(user2.address));

    await expect(
      royaltyAutomationRegistrar.connect(user1).register(registrationDetails)
    ).to.be.rejectedWith(Error);

    await royaltyAutomationRegistrar
      .connect(user2)
      .register(registrationDetails);

    console.log(
      "royaltyLinkBalance",
      await royaltyAdapter.getRoyaltyLinkBalance(tokenRoyaltySale.address)
    );
  });

  it("only token royalty admin can toggle automation", async () => {
    const [hubAdmin, user1, user2, user3, royaltyAddress] =
      await ethers.getSigners();

    let registrationDetails = {
      ticker: "ETH",
      jobId: jobId,
      oracle: oracleAddress,
      royaltyAddress: tokenRoyaltySale.address,
      adminAddress: user2.address,
      royaltyType: 1,
      updateInterval: 4,
      amount: ethers.utils.parseUnits("10", "ether"),
    };

    await linkToken.mint(ethers.utils.parseUnits("20", "ether"), user2.address);
    await linkToken
      .connect(user2)
      .approve(
        royaltyAutomationRegistrar.address,
        ethers.utils.parseUnits("20", "ether")
      );
    await royaltyAutomationRegistrar
      .connect(user2)
      .register(registrationDetails);

    await expect(
      royaltyAutomationRegistrar
        .connect(user1)
        .toggleAutomation(tokenRoyaltySale.address)
    ).to.be.rejectedWith(Error);

    await royaltyAutomationRegistrar
      .connect(user2)
      .toggleAutomation(tokenRoyaltySale.address);
  });

  it("Only token royalty admin should cancleAutomation", async () => {
    const [hubAdmin, user1, user2, user3, royaltyAddress] =
      await ethers.getSigners();

    let registrationDetails = {
      ticker: "ETH",
      jobId: jobId,
      oracle: oracleAddress,
      royaltyAddress: tokenRoyaltySale.address,
      adminAddress: user2.address,
      royaltyType: 1,
      updateInterval: 4,
      amount: ethers.utils.parseUnits("10", "ether"),
    };

    await linkToken.mint(ethers.utils.parseUnits("20", "ether"), user2.address);
    await linkToken
      .connect(user2)
      .approve(
        royaltyAutomationRegistrar.address,
        ethers.utils.parseUnits("20", "ether")
      );
    await royaltyAutomationRegistrar
      .connect(user2)
      .register(registrationDetails);

    await expect(
      royaltyAutomationRegistrar
        .connect(user1)
        .cancelAutomation(tokenRoyaltySale.address)
    ).to.be.rejectedWith(Error);

    await royaltyAutomationRegistrar
      .connect(user2)
      .cancelAutomation(tokenRoyaltySale.address);
  });
});
