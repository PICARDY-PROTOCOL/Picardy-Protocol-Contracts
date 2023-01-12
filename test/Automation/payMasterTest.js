const { assert, expect } = require("chai");
const chai = require("chai");
const { ethers } = require("hardhat");
chai.use(require("chai-as-promised"));

describe("PayMaster", async function () {
  let picardyHub;
  let payMaster;
  let ticker = "USDT";
  let usdtContract;
  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    const Usdt = await ethers.getContractFactory("MocLink");
    usdtContract = await Usdt.deploy();

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const PayMaster = await ethers.getContractFactory("PayMaster");
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

  it("user can sign up", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3, adapter] =
      await ethers.getSigners();

    await payMaster.connect(hubAdmin).addToken(ticker, usdtContract.address);

    await payMaster
      .connect(user1)
      .addRoyaltyData(adapter.address, royaltyAddress.address, 0);
  });

  it("owner can add reserve", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3, adapter] =
      await ethers.getSigners();

    await payMaster.connect(hubAdmin).addToken(ticker, usdtContract.address);

    await payMaster
      .connect(user1)
      .addRoyaltyData(adapter.address, royaltyAddress.address, 0);

    await expect(
      payMaster
        .connect(user1)
        .addETHReserve(adapter.address, 1000, { value: 100 })
    ).to.be.rejectedWith(Error);

    await payMaster.connect(user1).addETHReserve(adapter.address, 1000, {
      value: 1000,
    });
  });

  it("owner can add ERC reserve", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3, adapter] =
      await ethers.getSigners();

    await payMaster.connect(hubAdmin).addToken(ticker, usdtContract.address);

    await payMaster
      .connect(user1)
      .addRoyaltyData(adapter.address, royaltyAddress.address, 0);

    await expect(
      payMaster.connect(user1).addERC20Reserve(adapter.address, ticker, 100)
    ).to.be.rejectedWith(Error);

    await usdtContract.mint(100000, user1.address);
    await usdtContract.connect(user1).approve(payMaster.address, 1000);

    await payMaster
      .connect(user1)
      .addERC20Reserve(adapter.address, ticker, 1000);

    let royaltyReserve = await payMaster.getRoyaltyReserve(
      adapter.address,
      ticker
    );

    assert.equal(royaltyReserve, 1000);
  });

  // TODO: Fix this test
  //   it("adapter can send payment", async () => {
  //     const [hubAdmin, royaltyAddress, user1, user2, user3, adapter] =
  //       await ethers.getSigners();

  //     await payMaster.connect(hubAdmin).addToken(ticker, usdtContract.address);

  //     await payMaster
  //       .connect(user1)
  //       .addRoyaltyData(adapter.address, royaltyAddress.address, 0);

  //     await usdtContract.mint(100000, user1.address);
  //     await usdtContract.connect(user1).approve(payMaster.address, 1000);

  //     await payMaster
  //       .connect(user1)
  //       .addERC20Reserve(adapter.address, ticker, 1000);

  //     await payMaster.connect(adapter).sendPayment(adapter.address, ticker, 100);

  //     let royaltyReserve = await payMaster.getRoyaltyReserve(
  //       adapter.address,
  //       ticker
  //     );

  //     let paidOut = await payMaster.getRoyaltyPaid(adapter.address, ticker);

  //     assert.equal(royaltyReserve, 900);
  //     assert.equal(paidOut, 100);
  //   });
});
