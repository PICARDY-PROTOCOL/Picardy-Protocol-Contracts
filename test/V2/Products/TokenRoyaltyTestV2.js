const chai = require("chai");
const { assert, expect } = require("chai");
const { ethers } = require("hardhat");
const { waffle } = require("hardhat");
const provider = waffle.provider;
chai.use(require("chai-as-promised"));

describe("TokenRoyaltyTestV2", function () {
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
  let payoutToken;

  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    const MocLink = await ethers.getContractFactory("MocLink");
    linkToken = await MocLink.deploy();

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const CPToken = await ethers.getContractFactory("CPToken");

    const TokenRoyaltySaleFactory = await ethers.getContractFactory(
      "TokenRoyaltySaleFactoryV2"
    );

    const TokenRoyaltySaleImpl = await hre.ethers.getContractFactory(
      "TokenRoyaltySaleV2"
    );

    const PayoutToken = await ethers.getContractFactory("MocLink");
    payoutToken = await PayoutToken.deploy();

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
      .createTokenRoyalty(
        askAmount,
        returnPercentage,
        creatorsName,
        name,
        user1.address
      );

    const tokenAddress = await tokenRoyaltyFactory
      .connect(user1)
      .getTokenRoyaltyAddress(creatorsName, name);

    tokenRoyaltySale = await ethers.getContractAt(
      "TokenRoyaltySaleV2",
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
      tokenRoyaltySale.connect(user2).buyRoyalty(user2.address, {
        value: amount,
      })
    ).to.be.rejectedWith(Error);

    await tokenRoyaltySale.start();

    await tokenRoyaltySale.connect(user2).buyRoyalty(user2.address, {
      value: amount,
    });
  });

  // it: only owner can withdraw; test royalty state change, create royalty token from factroy
  it("only owner can withdraw", async () => {
    const amount1 = ethers.utils.parseUnits("5", "ether");
    const amount2 = ethers.utils.parseUnits("10", "ether");
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await tokenRoyaltySale.start();

    await tokenRoyaltySale.connect(user2).buyRoyalty(user2.address, {
      value: amount1,
    });

    await tokenRoyaltySale.connect(user3).buyRoyalty(user3.address, {
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
    const amountToSend = ethers.utils.parseUnits("10", "ether");
    const [hubAdmin, royaltyAddress, user1, user2, user3, user4, user5] =
      await ethers.getSigners();

    const trx = await tokenRoyaltySale.start();
    await trx.wait();

    await tokenRoyaltySale.connect(user2).buyRoyalty(user2.address, {
      value: amount1,
    });

    await tokenRoyaltySale.connect(user3).buyRoyalty(user3.address, {
      value: amount2,
    });

    const token = await ethers.getContractAt(
      "CPToken",
      await tokenRoyaltySale.getRoyatyTokenAddress(),
      user1
    );

    await token.connect(user2).transfer(user5.address, amountToSend);

    await tokenRoyaltySale.changeRoyaltyState();

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

    const sentUserRoyaltyBalance = await tokenRoyaltySale
      .connect(provider)
      .getRoyaltyBalance(user5.address);

    const user2PoolSize = await tokenRoyaltySale
      .connect(provider)
      .getMemberPoolSize(user2.address);

    const user3PoolSize = await tokenRoyaltySale
      .connect(provider)
      .getMemberPoolSize(user3.address);

    await tokenRoyaltySale
      .connect(user2)
      .withdrawRoyalty(user2RoyaltyBal, user2.address);
    await tokenRoyaltySale
      .connect(user3)
      .withdrawRoyalty(user3RoyaltyBal, user3.address);

    await tokenRoyaltySale
      .connect(user5)
      .withdrawRoyalty(sentUserRoyaltyBalance, user5.address);

    await expect(
      tokenRoyaltySale
        .connect(user4)
        .withdrawRoyalty(user2RoyaltyBal, user4.address)
    ).to.be.rejectedWith(Error);
  });

  // it: only royalty owner can withdraw royaltyERC20; send token to royalty contract
  it("only royalty owner can withdraw royaltyERC20", async () => {
    const amount1 = ethers.utils.parseUnits("40", "ether");
    const amount2 = ethers.utils.parseUnits("40", "ether");
    const amountToSend = ethers.utils.parseUnits("10", "ether");
    const [hubAdmin, royaltyAddress, user1, user2, user3, user4, user5] =
      await ethers.getSigners();

    const trx = await tokenRoyaltySale.start();
    await trx.wait();

    await tokenRoyaltySale.connect(user2).buyRoyalty(user2.address, {
      value: amount1,
    });

    await tokenRoyaltySale.connect(user3).buyRoyalty(user3.address, {
      value: amount2,
    });

    const token = await ethers.getContractAt(
      "CPToken",
      await tokenRoyaltySale.getRoyatyTokenAddress(),
      user1
    );

    await token.connect(user2).transfer(user5.address, amountToSend);

    await tokenRoyaltySale.changeRoyaltyState();

    await payoutToken.connect(user2).mint(royaltyAmount, user2.address);
    await tokenRoyaltySale.updateRoyalty(royaltyAmount, payoutToken.address);

    await payoutToken
      .connect(user2)
      .transfer(tokenRoyaltySale.address, royaltyAmount);

    const user2RoyaltyBal = await tokenRoyaltySale
      .connect(provider)
      .getERC20RoyaltyBalance(user2.address, payoutToken.address);

    const user3RoyaltyBal = await tokenRoyaltySale
      .connect(provider)
      .getERC20RoyaltyBalance(user3.address, payoutToken.address);

    const sentUserRoyaltyBalance = await tokenRoyaltySale
      .connect(provider)
      .getERC20RoyaltyBalance(user5.address, payoutToken.address);

    await tokenRoyaltySale
      .connect(user2)
      .withdrawERC20Royalty(
        user2RoyaltyBal,
        user2.address,
        payoutToken.address
      );
    await tokenRoyaltySale
      .connect(user3)
      .withdrawERC20Royalty(
        user3RoyaltyBal,
        user3.address,
        payoutToken.address
      );

    await tokenRoyaltySale
      .connect(user5)
      .withdrawERC20Royalty(
        sentUserRoyaltyBalance,
        user5.address,
        payoutToken.address
      );

    await expect(
      tokenRoyaltySale
        .connect(user4)
        .withdrawERC20Royalty(
          user2RoyaltyBal,
          user4.address,
          payoutToken.address
        )
    ).to.be.rejectedWith(Error);
  });
});
