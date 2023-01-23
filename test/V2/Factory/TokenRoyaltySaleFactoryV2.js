const chai = require("chai");
const { assert, expect } = require("chai");
const { ethers } = require("hardhat");
chai.use(require("chai-as-promised"));

describe("TokenRoyaltySaleFactoryV2", function () {
  const askAmount = 1e7;
  const returnPercentage = 20;
  const creatorsName = "testCreator";
  const name = "testToken";

  let picardyHub;
  let tokenRoyaltySaleFactory;
  let tokenRoyaltyImpAddress;
  const linkToken = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";

  beforeEach(async () => {
    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const TokenRoyaltySaleFactory = await ethers.getContractFactory(
      "TokenRoyaltySaleFactoryV2"
    );

    const TokenRoyaltySaleImpl = await hre.ethers.getContractFactory(
      "TokenRoyaltySaleV2"
    );

    const tokenRoyaltyImp = await TokenRoyaltySaleImpl.deploy();
    await tokenRoyaltyImp.deployed();
    tokenRoyaltyImpAddress = tokenRoyaltyImp.address;

    tokenRoyaltySaleFactory = await TokenRoyaltySaleFactory.deploy(
      picardyHub.address,
      linkToken,
      tokenRoyaltyImpAddress
    );

    //deploy mocLink
    //mint mocLink to user
  });

  it("user can create a token royalty sale", async () => {
    const [hubAdmin, user, royaltyAddress] = await ethers.getSigners();
    const tx = await tokenRoyaltySaleFactory
      .connect(user)
      .createTokenRoyalty(
        askAmount,
        returnPercentage,
        creatorsName,
        name,
        user.address
      );

    const tokenRoyaltyAddress =
      await tokenRoyaltySaleFactory.getTokenRoyaltyAddress(creatorsName, name);

    const receipt = await tx.wait();

    const events = [];
    for (let item of receipt.events) {
      events.push(item.event);
    }

    let eventIndex = events.length - 1;
    expect(events).to.include("TokenRoyaltyCreated");

    assert.equal(await receipt.events[eventIndex].args.creator, user.address);
    assert.equal(
      await receipt.events[eventIndex].args.tokenRoyaltyAddress,
      tokenRoyaltyAddress
    );
    assert.equal(await receipt.events[eventIndex].args.royaltyId, 1);
  });

  it("Only hub Admin can update royalty details", async () => {
    const [hubAdmin, user, royaltyAddress] = await ethers.getSigners();
    const hub = await picardyHub.connect(hubAdmin);
    const tokenFactroy = tokenRoyaltySaleFactory.connect(user);

    await hub.updateRoyaltyAddress(royaltyAddress.address);

    await expect(tokenFactroy.updateRoyaltyDetails(10)).to.be.rejectedWith(
      Error
    );
    await expect(
      tokenRoyaltySaleFactory.connect(hubAdmin).updateRoyaltyDetails(60)
    ).to.be.rejectedWith(Error);

    const tx = await tokenRoyaltySaleFactory
      .connect(hubAdmin)
      .updateRoyaltyDetails(10);

    const receipt = await tx.wait();

    const data = await tokenRoyaltySaleFactory.getRoyaltyDetails();

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
