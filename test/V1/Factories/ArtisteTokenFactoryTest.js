const { assert, expect } = require("chai");
const chai = require("chai");
const { ethers } = require("hardhat");
chai.use(require("chai-as-promised"));

describe("ArtisteTokenFactory", function () {
  const totalAmount = 1e7;
  const name = "testToken";
  const symbol = "TT";
  const cost = 1;

  let picardyHub;
  let artisteTokenFactory;
  beforeEach(async () => {
    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const AtristeTokenFactory = await ethers.getContractFactory(
      "ArtisteTokenFactory"
    );
    artisteTokenFactory = await AtristeTokenFactory.deploy(picardyHub.address);
  });

  it("user can create token", async () => {
    const [hubAdmin, user, royaltyAddress] = await ethers.getSigners();
    const tokenFactroy = artisteTokenFactory.connect(user);
    const tx = await tokenFactroy.createArtisteToken(
      totalAmount,
      name,
      symbol,
      cost
    );

    const receipt = await tx.wait();
    const tokenAddress = await tokenFactroy.getTokenAddress(name, symbol);

    const events = [];
    for (let item of receipt.events) {
      events.push(item.event);
      //console.log("event args", item.args);
    }

    expect(events).to.include("NewArtisteTokenCreated");

    assert.equal(await receipt.events[2].args.tokenId, 1);
    assert.equal(await receipt.events[2].args.totalAmount, 1e7);
    assert.equal(await receipt.events[2].args.tokenAddress, tokenAddress);
  });

  it("Only hub Admin can update royalty details", async () => {
    const [hubAdmin, user, royaltyAddress] = await ethers.getSigners();
    const hub = await picardyHub.connect(hubAdmin);
    const tokenFactroy = artisteTokenFactory.connect(user);

    await hub.updateRoyaltyAddress(royaltyAddress.address);

    await expect(tokenFactroy.updateRoyaltyDetails(10)).to.be.rejectedWith(
      Error
    );

    const tx = await artisteTokenFactory
      .connect(hubAdmin)
      .updateRoyaltyDetails(10);
    const receipt = await tx.wait();

    const data = await artisteTokenFactory.getRoyaltyDetails();

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
