const chai = require("chai");
const { assert, expect } = require("chai");
const { ethers } = require("hardhat");
const { waffle } = require("hardhat");
const provider = waffle.provider;
chai.use(require("chai-as-promised"));

describe("PicardyArtisteToken", function () {
  const totalAmount = 1e7;
  const name = "testToken";
  const symbol = "TT";
  const cost = 1;

  let picardyHub;
  let artisteTokenFactory;
  let artisteToken;
  let artisteTokenAddress;
  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();
    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const AtristeTokenFactory = await ethers.getContractFactory(
      "ArtisteTokenFactory"
    );
    artisteTokenFactory = await AtristeTokenFactory.deploy(picardyHub.address);
    await artisteTokenFactory
      .connect(user1)
      .createArtisteToken(
        totalAmount,
        name,
        symbol,
        ethers.utils.parseUnits(cost.toString(), "ether")
      );

    artisteTokenAddress = await artisteTokenFactory.getTokenAddress(
      name,
      symbol
    );

    artisteToken = await ethers.getContractAt(
      "PicardyArtisteToken",
      artisteTokenAddress,
      user1
    );

    await picardyHub
      .connect(hubAdmin)
      .updateRoyaltyAddress(royaltyAddress.address);
    await artisteTokenFactory.connect(hubAdmin).updateRoyaltyDetails(10);
  });

  it("user can mint tokne ", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    let mintAmount = 10;
    let totalValue = mintAmount * cost;
    let formatedCost = ethers.utils.parseUnits(totalValue.toString(), "ether");

    await artisteToken.mint(10, user1.address, { value: formatedCost });

    await expect(
      artisteToken.mint(10, user1.address, {
        value: ethers.utils.parseUnits("5", "ether"),
      })
    ).to.be.rejectedWith(Error);
  });

  it("only owner should withdraw", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(artisteToken.connect(user2).withdraw()).to.be.rejectedWith(
      Error
    );

    await artisteToken.withdraw();
  });
});
