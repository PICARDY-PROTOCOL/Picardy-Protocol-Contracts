const { assert, expect } = require("chai");
const chai = require("chai");
const { ethers } = require("hardhat");
chai.use(require("chai-as-promised"));

describe("NftRoyaltySaleFactoryV2", function () {
  const maxSupply = 10;
  const maxMintAmount = 2;
  const cost = ethers.utils.parseUnits("1", "ether"); // 1 eth
  const percentage = 10;
  const name = "testToken";
  const symbol = "TST";
  const initBaseURI = "https://test.com/";
  const creatorName = "testArtiste";
  //const linkToken = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";

  let picardyHub;
  let nftRoyaltySaleFactory;
  let linkToken;
  let tokenContract;
  let nftRoyaltyImpAddress;

  beforeEach(async () => {
    const [hubAdmin, user, royaltyAddress] = await ethers.getSigners();

    const LinkToken = await ethers.getContractFactory("MocLink");
    tokenContract = await LinkToken.deploy();
    linkToken = tokenContract.address;

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const NftRoyaltySaleImpl = await hre.ethers.getContractFactory(
      "NftRoyaltySaleV2"
    );

    const nftRoyaltyImp = await NftRoyaltySaleImpl.deploy();
    await nftRoyaltyImp.deployed();
    nftRoyaltyImpAddress = nftRoyaltyImp.address;

    const NftRoyaltySaleFactory = await ethers.getContractFactory(
      "NftRoyaltySaleFactoryV2"
    );
    nftRoyaltySaleFactory = await NftRoyaltySaleFactory.deploy(
      picardyHub.address,
      linkToken,
      nftRoyaltyImpAddress
    );
  });

  it("user can create nft royalty sale", async () => {
    const [hubAdmin, user, royaltyAddress] = await ethers.getSigners();

    let details = {
      maxSupply: maxSupply,
      maxMintAmount: maxMintAmount,
      cost: cost,
      percentage: percentage,
      name: name,
      symbol: symbol,
      initBaseURI: initBaseURI,
      creatorName: creatorName,
      creator: user.address,
    };

    let eventIndex;
    const tx = await nftRoyaltySaleFactory
      .connect(user)
      .createNftRoyalty(details);
    const nftRoyaltySaleAddress = await nftRoyaltySaleFactory
      .connect(user)
      .getNftRoyaltySaleAddress(creatorName, name);

    const receipt = await tx.wait();

    const events = [];
    for (let item of receipt.events) {
      events.push(item.event);
    }

    eventIndex = events.length - 1;
    expect(events).to.include("NftRoyaltySaleCreated");

    assert.equal(await receipt.events[eventIndex].args.royaltySaleId, 1);
    assert.equal(
      await receipt.events[eventIndex].args.royaltySaleAddress,
      nftRoyaltySaleAddress
    );
    assert.equal(await receipt.events[eventIndex].args.creator, user.address);
  });

  it("Only hub Admin can update royalty details", async () => {
    const [hubAdmin, user, royaltyAddress] = await ethers.getSigners();
    const hub = await picardyHub.connect(hubAdmin);
    const tokenFactroy = nftRoyaltySaleFactory.connect(user);

    await hub.updateRoyaltyAddress(royaltyAddress.address);

    await expect(tokenFactroy.updateRoyaltyDetails(10)).to.be.rejectedWith(
      Error
    );

    const tx = await nftRoyaltySaleFactory
      .connect(hubAdmin)
      .updateRoyaltyDetails(10);

    const receipt = await tx.wait();

    const data = await nftRoyaltySaleFactory.getRoyaltyDetails();

    const { 0: addr, 1: percentage } = data;
    assert.equal(addr, royaltyAddress.address);
    assert.equal(percentage, 10);

    const events = [];
    for (let item of receipt.events) {
      events.push(item.event);
    }

    expect(events).to.include("RoyaltyDetailsUpdated");

    assert.equal(await receipt.events[0].args.percentage, 10);
    assert.equal(
      await receipt.events[0].args.royaltyAddress,
      royaltyAddress.address
    );
  });
});
