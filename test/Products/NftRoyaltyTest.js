const chai = require("chai");
const { assert, expect } = require("chai");
const { ethers } = require("hardhat");
const { waffle } = require("hardhat");
const provider = waffle.provider;
chai.use(require("chai-as-promised"));

describe("NftRoyaltySale", function () {
  const maxSupply = 100;
  const maxMintAmount = 20;
  const formatedCost = ethers.utils.parseUnits("1", "ether"); // 1 eth
  const percentage = 10;
  const name = "testToken";
  const symbol = "TST";
  const initBaseURI = "https://test.com/";
  const artisteName = "testArtiste";
  let linkToken;

  let picardyHub;
  let nftRoyaltySaleFactory;
  let nftRoyaltySaleAddress;
  let nftRoyaltySale;
  let tokenContract;
  let nftRoyaltyImpAddress;

  let details = {
    maxSupply: maxSupply,
    maxMintAmount: maxMintAmount,
    cost: formatedCost,
    percentage: percentage,
    name: name,
    symbol: symbol,
    initBaseURI: initBaseURI,
    artisteName: artisteName,
  };

  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    let LinkToken = await ethers.getContractFactory("MocLink");
    tokenContract = await LinkToken.deploy();
    linkToken = tokenContract.address;

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

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

    const tx = await nftRoyaltySaleFactory
      .connect(user1)
      .createNftRoyalty(details);

    nftRoyaltySaleAddress =
      await nftRoyaltySaleFactory.getNftRoyaltySaleAddress(artisteName, name);

    nftRoyaltySale = await ethers.getContractAt(
      "NftRoyaltySale",
      nftRoyaltySaleAddress,
      user1
    );
  });

  //it: only owner should start
  it("only owner should start", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(nftRoyaltySale.connect(user2).start()).to.be.rejectedWith(
      Error
    );

    await nftRoyaltySale.start();
  });

  //it: only owner should setup automation
  it("only owner should setup automation", async () => {
    const [
      hubAdmin,
      royaltyAddress,
      regAddress,
      royaltyAdapter,
      user1,
      user2,
      user3,
    ] = await ethers.getSigners();

    let timeInterval = 2;

    await nftRoyaltySale.start();

    await expect(
      nftRoyaltySale
        .connect(user2)
        .setupAutomation(
          regAddress.address,
          timeInterval,
          royaltyAdapter.address
        )
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale.setupAutomation(
      regAddress.address,
      timeInterval,
      royaltyAdapter.address
    );
  });
  //it: only owner should toggle automation
  it(" only owner should toggle automation", async () => {
    const [
      hubAdmin,
      royaltyAddress,
      regAddress,
      royaltyAdapter,
      user1,
      user2,
      user3,
    ] = await ethers.getSigners();

    await nftRoyaltySale.start();

    await expect(
      nftRoyaltySale.connect(user2).toggleAutomation()
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale.toggleAutomation();
  });
  //it: user can buy royalty
  it("users can buy royalty", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();
    const cost = 1;
    const mintAmount = 2;
    let total = cost * mintAmount;

    const formattedTotal = ethers.utils.parseUnits(total.toString(), "ether");

    await nftRoyaltySale.start();

    await expect(
      nftRoyaltySale.connect(user3).buyRoyalty(2, {
        value: ethers.utils.parseUnits("0.5", "ether"),
      })
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale
      .connect(user2)
      .buyRoyalty(2, { value: formattedTotal });
    await nftRoyaltySale
      .connect(user3)
      .buyRoyalty(2, { value: formattedTotal });
  });
  //it: owner should update royalty only when automation is turned off
  it("owner should update royalty only when automation is turned off", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    const updateAmount = ethers.utils.parseUnits("100", "ether");

    await nftRoyaltySale.start();

    await nftRoyaltySale.connect(user2).buyRoyalty(2, { value: updateAmount });
    await nftRoyaltySale.connect(user3).buyRoyalty(2, { value: updateAmount });

    await expect(
      nftRoyaltySale.connect(user2).toggleRoyaltSale()
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale.toggleRoyaltSale();
  });
  //it: owner can pause and unpause the base NFT contract
  it("owner can pause and unpause the base NFT contract", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await nftRoyaltySale.start();

    await expect(
      nftRoyaltySale.connect(user2).pauseTokenBase()
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale.pauseTokenBase();

    await expect(
      nftRoyaltySale.connect(user2).unPauseTokenBase()
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale.unPauseTokenBase();
  });
  //it ownly owner can withdraw
  it("ownly owner can withdraw", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();
    const cost = 1;
    const mintAmount = 2;
    let total = cost * mintAmount;
    const formattedTotal = ethers.utils.parseUnits(total.toString(), "ether");

    await nftRoyaltySale.start();

    await nftRoyaltySale
      .connect(user2)
      .buyRoyalty(2, { value: formattedTotal });
    await nftRoyaltySale
      .connect(user3)
      .buyRoyalty(2, { value: formattedTotal });

    await expect(nftRoyaltySale.connect(user2).withdraw()).to.be.rejectedWith(
      Error
    );
    await nftRoyaltySale.toggleRoyaltSale();
    await nftRoyaltySale.withdraw();
  });

  //it royaltyHolders can withdraw
  it("royaltyHolders can withdraw", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3, user4, user5, user6] =
      await ethers.getSigners();
    const cost = 1;
    const mintAmount = 2;
    let total = cost * mintAmount;
    const updateAmount = ethers.utils.parseUnits("10", "ether");
    const formattedTotal = ethers.utils.parseUnits(total.toString(), "ether");

    await nftRoyaltySale.start();

    await nftRoyaltySale
      .connect(user2)
      .buyRoyalty(1, { value: ethers.utils.parseUnits("1", "ether") });
    await nftRoyaltySale
      .connect(user3)
      .buyRoyalty(2, { value: formattedTotal });

    await nftRoyaltySale
      .connect(user4)
      .buyRoyalty(3, { value: ethers.utils.parseUnits("3", "ether") });

    await nftRoyaltySale
      .connect(user5)
      .buyRoyalty(4, { value: ethers.utils.parseUnits("4", "ether") });

    await nftRoyaltySale
      .connect(user6)
      .buyRoyalty(15, { value: ethers.utils.parseUnits("15", "ether") });

    await nftRoyaltySale.toggleRoyaltSale();

    await user1.sendTransaction({
      to: nftRoyaltySale.address,
      value: updateAmount,
    });

    await expect(
      nftRoyaltySale.connect(user2).withdrawRoyalty()
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale.toggleRoyaltSale();

    await nftRoyaltySale
      .connect(user2)
      .withdrawRoyalty(await nftRoyaltySale.royaltyBalance(user2.address));

    await nftRoyaltySale
      .connect(user3)
      .withdrawRoyalty(await nftRoyaltySale.royaltyBalance(user3.address));

    await expect(
      nftRoyaltySale
        .connect(user3)
        .withdrawRoyalty(ethers.utils.parseUnits("4", "ether"))
    ).to.be.rejectedWith(Error);
  });
});

describe("PicardyNftBase", function () {
  const maxSupply = 100;
  const maxMintAmount = 20;
  const formatedCost = ethers.utils.parseUnits("1", "ether"); // 1 eth
  const percentage = 10;
  const name = "testToken";
  const symbol = "TST";
  const initBaseURI = "https://test.com/";
  const artisteName = "testArtiste";
  let linkToken;

  let picardyHub;
  let nftRoyaltySaleFactory;
  let nftRoyaltySaleAddress;
  let nftRoyaltySale;
  let tokenContract;
  let nftRoyaltyAddress;
  let nftBase;
  let nftRoyaltyImpAddress;

  let details = {
    maxSupply: maxSupply,
    maxMintAmount: maxMintAmount,
    cost: formatedCost,
    percentage: percentage,
    name: name,
    symbol: symbol,
    initBaseURI: initBaseURI,
    artisteName: artisteName,
  };

  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    let LinkToken = await ethers.getContractFactory("MocLink");
    tokenContract = await LinkToken.deploy();
    linkToken = tokenContract.address;

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

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

    const tx = await nftRoyaltySaleFactory
      .connect(user1)
      .createNftRoyalty(details);

    nftRoyaltySaleAddress =
      await nftRoyaltySaleFactory.getNftRoyaltySaleAddress(artisteName, name);

    nftRoyaltySale = await ethers.getContractAt(
      "NftRoyaltySale",
      nftRoyaltySaleAddress,
      user1
    );

    await nftRoyaltySale.start();

    nftRoyaltyAddress = await nftRoyaltySale.nftRoyaltyAddress();
    nftBase = await ethers.getContractAt(
      "PicardyNftBase",
      nftRoyaltyAddress,
      user1
    );
  });

  //it: only sale contract can buy royalty
  it("only sale contract can call buyroyalty function", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(nftBase.buyRoyalty(2, user1.address)).to.be.rejectedWith(
      Error
    );
  });
  //it: only owner can update token state
  it("only owner can update token state", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      nftBase.connect(user2).setMaxMintAmount(maxMintAmount)
    ).to.be.rejectedWith(Error);

    await expect(
      nftBase.connect(user2).setBaseURI(initBaseURI)
    ).to.be.rejectedWith(Error);

    await expect(
      nftBase.connect(user2).setBaseExtension(".json")
    ).to.be.rejectedWith(Error);

    await nftBase.setMaxMintAmount(maxMintAmount);
    await nftBase.setBaseURI(initBaseURI);
    await nftBase.setBaseExtension(".json");
  });
  //it: onlyowner can withdraw
  it("only owner can withdraw", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();
    await expect(
      nftBase.connect(user2).withdraw(user2.address)
    ).to.be.rejectedWith(Error);

    await nftBase.withdraw(user1.address);
  });

  it("only sale contract can pause and unpause", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(nftBase.connect(user2).pause()).to.be.rejectedWith(Error);
    await expect(nftBase.connect(user2).unpause()).to.be.rejectedWith(Error);
  });
});
