const chai = require("chai");
const { assert, expect } = require("chai");
const { ethers } = require("hardhat");
const { waffle } = require("hardhat");
const provider = waffle.provider;
chai.use(require("chai-as-promised"));

describe("TokenRoyaltyTest", function () {
  const askAmount = ethers.utils.parseUnits("100", "ether");
  const returnPercentage = 20;
  const creatorsName = "testCreator";
  const name = "testToken";
  const royaltyAmount = ethers.utils.parseUnits("50", "ether");

  let picardyHub;
  let tokenRoyaltyFactory;
  let tokenRoyaltySale;
  let linkToken;
  let tokenRoyaltyImpAddress;

  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    const MocLink = await ethers.getContractFactory("MocLink");
    linkToken = await MocLink.deploy();

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

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
      linkToken.address,
      tokenRoyaltyImpAddress
    );

    await tokenRoyaltyFactory
      .connect(user1)
      .createTokenRoyalty(askAmount, returnPercentage, creatorsName, name);

    const tokenAddress = await tokenRoyaltyFactory
      .connect(user1)
      .getTokenRoyaltyAddress(1);

    tokenRoyaltySale = await ethers.getContractAt(
      "TokenRoyaltySale",
      tokenAddress,
      user1
    );

    await picardyHub.updateRoyaltyAddress(royaltyAddress.address);
    await tokenRoyaltyFactory.updateRoyaltyDetails(10);
    //create royalty token from factroy
  });

  // it: only owner should start, create royalty token from factory
  it(" only owner should start", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(tokenRoyaltySale.connect(user2).start()).to.be.rejectedWith(
      Error
    );

    await tokenRoyaltySale.start();
  });

  // it: users can buy royalty, create royalty token from factroy
  it("user can buy token", async () => {
    const amount = ethers.utils.parseUnits("5", "ether");
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      tokenRoyaltySale.connect(user2).buyRoyalty({
        value: amount,
      })
    ).to.be.rejectedWith(Error);

    await tokenRoyaltySale.start();

    await tokenRoyaltySale.connect(user2).buyRoyalty({
      value: amount,
    });
  });

  // it: only royalty adapter and owner can update royalty, create royalty token from factroy
  it("owner can update royalty", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      tokenRoyaltySale.connect(user2).ownerUpdateRoyalty(royaltyAmount)
    ).to.be.rejectedWith(Error);

    const tx = await tokenRoyaltySale.ownerUpdateRoyalty(royaltyAmount);
    const receipt = await tx.wait();

    const events = [];
    for (let item of receipt.events) {
      events.push(item.event);
    }

    expect(events).to.include("RoyaltyBalanceUpdated");
  });

  // it: only owner can withdraw; test royalty state change, create royalty token from factroy
  it("only owner can withdraw", async () => {
    const amount1 = ethers.utils.parseUnits("5", "ether");
    const amount2 = ethers.utils.parseUnits("10", "ether");
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await tokenRoyaltySale.start();

    await tokenRoyaltySale.connect(user2).buyRoyalty({
      value: amount1,
    });

    await tokenRoyaltySale.connect(user3).buyRoyalty({
      value: amount2,
    });

    await expect(
      tokenRoyaltySale.connect(user3).changeRoyaltyState()
    ).to.be.rejectedWith(Error);

    await tokenRoyaltySale.changeRoyaltyState();

    await expect(tokenRoyaltySale.connect(user3).withdraw()).to.be.rejectedWith(
      Error
    );

    const beforeWithdrawal = await provider.getBalance(
      tokenRoyaltySale.address
    );

    await tokenRoyaltySale.withdraw();

    const afterWithdrawal = await provider.getBalance(tokenRoyaltySale.address);

    expect(beforeWithdrawal.toString()).to.equal("15000000000000000000");
    expect(afterWithdrawal).to.equal(0);

    // console.log("before Withdrawal:", beforeWithdrawal);
    // console.log("After Withdrawal:", afterWithdrawal);
  });

  // it: only royalty owner can withdraw royalty; send token to royalty contract
  it("holders can withdraw royalty balance", async () => {
    const amount1 = ethers.utils.parseUnits("40", "ether");
    const amount2 = ethers.utils.parseUnits("40", "ether");
    const [hubAdmin, royaltyAddress, user1, user2, user3, user4] =
      await ethers.getSigners();

    const trx = await tokenRoyaltySale.start();
    await trx.wait();

    await tokenRoyaltySale.connect(user2).buyRoyalty({
      value: amount1,
    });

    await tokenRoyaltySale.connect(user3).buyRoyalty({
      value: amount2,
    });

    await tokenRoyaltySale.changeRoyaltyState();

    const tx = await tokenRoyaltySale.ownerUpdateRoyalty(royaltyAmount);
    const receipt = await tx.wait();

    const events = [];
    for (let item of receipt.events) {
      events.push(item.event);
    }

    expect(events).to.include("RoyaltyBalanceUpdated");

    await user1.sendTransaction({
      to: tokenRoyaltySale.address,
      value: royaltyAmount,
    });

    const balanceAfterDeposi = await provider.getBalance(
      tokenRoyaltySale.address
    );

    const user2RoyaltyBal = await tokenRoyaltySale
      .connect(provider)
      .getRoyaltyBalance(user2.address);

    const user3RoyaltyBal = await tokenRoyaltySale
      .connect(provider)
      .getRoyaltyBalance(user3.address);

    const user2PoolSize = await tokenRoyaltySale
      .connect(provider)
      .getMemberPoolSize(user2.address);

    const user3PoolSize = await tokenRoyaltySale
      .connect(provider)
      .getMemberPoolSize(user3.address);

    await tokenRoyaltySale.connect(user2).withdrawRoyalty(user2RoyaltyBal);
    await tokenRoyaltySale.connect(user3).withdrawRoyalty(user3RoyaltyBal);

    await expect(
      tokenRoyaltySale.connect(user4).withdrawRoyalty(user2RoyaltyBal)
    ).to.be.rejectedWith(Error);

    // console.log(
    //   "Royalty Balance",
    //   user2RoyaltyBal.toString(),
    //   user3RoyaltyBal.toString()
    // );
    // console.log("pool size:", user2PoolSize, ":", user3PoolSize);

    // console.log(
    //   await tokenRoyaltySale.connect(provider).getRoyaltyPercentage()
    // );

    // console.log("balanceAfterDeposi:", balanceAfterDeposi.toString());
  });
});
