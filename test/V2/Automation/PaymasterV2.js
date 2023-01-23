const { assert, expect } = require("chai");
const chai = require("chai");
const { ethers } = require("hardhat");
chai.use(require("chai-as-promised"));

describe("PayMasterV2", function () {
  let picardyHub;
  let payMaster;
  let ticker = "USDT";
  let usdtContract;

  beforeEach(async () => {
    const Usdt = await ethers.getContractFactory("MocLink");
    usdtContract = await Usdt.deploy();

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const PayMaster = await ethers.getContractFactory("PayMasterV2");
    payMaster = await PayMaster.deploy(picardyHub.address);
  });

  it("only hubAdmin can add tokens", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      payMaster.connect(user1).addToken(ticker, usdtContract.address)
    ).to.be.rejectedWith(Error);

    await payMaster.connect(hubAdmin).addToken(ticker, usdtContract.address);
  });

  it("only hubAdmin can remove tokens", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await payMaster.connect(hubAdmin).addToken(ticker, usdtContract.address);

    await expect(
      payMaster.connect(user1).removeToken(ticker)
    ).to.be.rejectedWith(Error);

    await payMaster.connect(hubAdmin).removeToken(ticker);
  });

  it("only registrar can add Royalty data", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3, adapter] =
      await ethers.getSigners();

    await payMaster.connect(hubAdmin).addToken(ticker, usdtContract.address);

    await expect(
      payMaster
        .connect(user1)
        .addRoyaltyData(adapter.address, royaltyAddress.address, 0, ticker)
    ).to.be.rejectedWith(Error);
  });

  it("owner can add reserve", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3, adapter] =
      await ethers.getSigners();

    await payMaster.connect(hubAdmin).addToken(ticker, usdtContract.address);

    await expect(
      payMaster
        .connect(user1)
        .addETHReserve(adapter.address, 1000, { value: 100 })
    ).to.be.rejectedWith(Error);
  });

  it("owner can add ERC reserve", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3, adapter] =
      await ethers.getSigners();

    await payMaster.connect(hubAdmin).addToken(ticker, usdtContract.address);

    await expect(
      payMaster.connect(user1).addERC20Reserve(adapter.address, ticker, 100)
    ).to.be.rejectedWith(Error);
  });
});
