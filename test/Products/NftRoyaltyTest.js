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
  const creatorName = "testArtiste";
  let linkToken;
  let payoutToken;

  let picardyHub;
  let nftRoyaltySaleFactory;
  let nftRoyaltySaleAddress;
  let nftRoyaltySale;
  let tokenContract;
  let nftRoyaltyImpAddress;

  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    let details = {
      maxSupply: maxSupply,
      maxMintAmount: maxMintAmount,
      cost: formatedCost,
      percentage: percentage,
      name: name,
      symbol: symbol,
      initBaseURI: initBaseURI,
      creatorName: creatorName,
      creator: user1.address,
    };

    let LinkToken = await ethers.getContractFactory("MocLink");
    tokenContract = await LinkToken.deploy();
    linkToken = tokenContract.address;

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const NftRoyaltySaleImpl = await hre.ethers.getContractFactory(
      "NftRoyaltySale"
    );

    const PayoutToken = await ethers.getContractFactory("MocLink");
    payoutToken = await PayoutToken.deploy();

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
      await nftRoyaltySaleFactory.getNftRoyaltySaleAddress(creatorName, name);

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
  it("only regstrar setup automation", async () => {
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
        .setupAutomation(timeInterval, royaltyAdapter.address)
    ).to.be.rejectedWith(Error);
  });
  // it(" only owner and royaltyRegistrar should toggle automation", async () => {
  //   const [
  //     hubAdmin,
  //     royaltyAddress,
  //     regAddress,
  //     royaltyAdapter,
  //     user1,
  //     user2,
  //     user3,
  //   ] = await ethers.getSigners();

  //   await nftRoyaltySale.start();

  //   await expect(
  //     nftRoyaltySale.connect(user2).toggleAutomation()
  //   ).to.be.rejectedWith(Error);

  //   await expect(await nftRoyaltySale.toggleAutomation()).to.be.rejectedWith(
  //     Error
  //   );
  // });
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
      nftRoyaltySale.connect(user3).buyRoyalty(2, user3.address, {
        value: ethers.utils.parseUnits("0.5", "ether"),
      })
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale
      .connect(user2)
      .buyRoyalty(2, user2.address, { value: formattedTotal });
    await nftRoyaltySale
      .connect(user3)
      .buyRoyalty(2, user3.address, { value: formattedTotal });
  });
  //it: owner should update royalty only when automation is turned off
  it("owner should update royalty only when automation is turned off", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    const updateAmount = ethers.utils.parseUnits("100", "ether");

    await nftRoyaltySale.start();

    await nftRoyaltySale
      .connect(user2)
      .buyRoyalty(2, user2.address, { value: updateAmount });
    await nftRoyaltySale
      .connect(user3)
      .buyRoyalty(2, user3.address, { value: updateAmount });

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
      .buyRoyalty(2, user2.address, { value: formattedTotal });
    await nftRoyaltySale
      .connect(user3)
      .buyRoyalty(2, user3.address, { value: formattedTotal });

    await expect(nftRoyaltySale.connect(user2).withdraw()).to.be.rejectedWith(
      Error
    );
    await nftRoyaltySale.toggleRoyaltSale();
    await nftRoyaltySale.withdraw();
  });
  //it royaltyHolders can withdraw
  it("royaltyHolders can withdraw", async () => {
    const [
      hubAdmin,
      royaltyAddress,
      user1,
      user2,
      user3,
      user4,
      user5,
      user6,
      user7,
    ] = await ethers.getSigners();
    const cost = 1;
    const mintAmount = 2;
    let total = cost * mintAmount;
    const updateAmount = ethers.utils.parseUnits("10", "ether");
    const formattedTotal = ethers.utils.parseUnits(total.toString(), "ether");
    const token = await ethers.getContractAt(
      "PicardyNftBase",
      nftRoyaltySale.getRoyaltyTokenAddress()
    );

    await nftRoyaltySale.start();

    await nftRoyaltySale.connect(user2).buyRoyalty(1, user2.address, {
      value: ethers.utils.parseUnits("1", "ether"),
    });

    await nftRoyaltySale
      .connect(user3)
      .buyRoyalty(2, user3.address, { value: formattedTotal });

    await nftRoyaltySale.connect(user4).buyRoyalty(3, user4.address, {
      value: ethers.utils.parseUnits("3", "ether"),
    });

    await nftRoyaltySale.connect(user5).buyRoyalty(4, user5.address, {
      value: ethers.utils.parseUnits("4", "ether"),
    });

    await nftRoyaltySale.connect(user6).buyRoyalty(15, user6.address, {
      value: ethers.utils.parseUnits("15", "ether"),
    });

    await token.connect(user6).transferFrom(user6.address, user7.address, 12);

    await expect(
      nftRoyaltySale
        .connect(user2)
        .withdrawRoyalty(
          await nftRoyaltySale.royaltyBalance(user2.address),
          user2.address
        )
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale.toggleRoyaltSale();

    await user1.sendTransaction({
      to: nftRoyaltySale.address,
      value: updateAmount,
    });

    await nftRoyaltySale
      .connect(user2)
      .withdrawRoyalty(
        await nftRoyaltySale.royaltyBalance(user2.address),
        user2.address
      );

    await nftRoyaltySale
      .connect(user3)
      .withdrawRoyalty(
        await nftRoyaltySale.royaltyBalance(user3.address),
        user3.address
      );

    await nftRoyaltySale
      .connect(user7)
      .withdrawRoyalty(
        await nftRoyaltySale.royaltyBalance(user7.address),
        user7.address
      );

    await expect(
      nftRoyaltySale
        .connect(user3)
        .withdrawRoyalty(ethers.utils.parseUnits("4", "ether"))
    ).to.be.rejectedWith(Error);
  });
  //it: only royaltyholdersCan withdraw ERC20Royalty
  it("only royaltyholdersCan withdraw ERC20Royalty", async () => {
    const [
      hubAdmin,
      royaltyAddress,
      user1,
      user2,
      user3,
      user4,
      user5,
      user6,
      user7,
    ] = await ethers.getSigners();
    const cost = 1;
    const mintAmount = 2;
    let total = cost * mintAmount;
    const updateAmount = ethers.utils.parseUnits("10", "ether");
    const formattedTotal = ethers.utils.parseUnits(total.toString(), "ether");

    const token = await ethers.getContractAt(
      "PicardyNftBase",
      nftRoyaltySale.getRoyaltyTokenAddress()
    );

    await nftRoyaltySale.start();

    await nftRoyaltySale.connect(user2).buyRoyalty(1, user2.address, {
      value: ethers.utils.parseUnits("1", "ether"),
    });

    await nftRoyaltySale
      .connect(user3)
      .buyRoyalty(2, user3.address, { value: formattedTotal });

    await nftRoyaltySale.connect(user5).buyRoyalty(4, user5.address, {
      value: ethers.utils.parseUnits("4", "ether"),
    });

    await nftRoyaltySale.connect(user6).buyRoyalty(15, user6.address, {
      value: ethers.utils.parseUnits("15", "ether"),
    });

    await token.connect(user6).transferFrom(user6.address, user7.address, 12);

    await expect(
      nftRoyaltySale
        .connect(user2)
        .withdrawRoyalty(
          await nftRoyaltySale.royaltyBalance(user2.address),
          user2.address
        )
    ).to.be.rejectedWith(Error);

    await nftRoyaltySale.toggleRoyaltSale();
    await payoutToken.connect(user2).mint(updateAmount, user2.address);
    await nftRoyaltySale.updateRoyalty(updateAmount, payoutToken.address);

    await payoutToken
      .connect(user2)
      .transfer(nftRoyaltySale.address, updateAmount);

    const user2RoyaltyBal = await nftRoyaltySale
      .connect(provider)
      .getERC20RoyaltyBalance(user2.address, payoutToken.address);

    const user3RoyaltyBal = await nftRoyaltySale
      .connect(provider)
      .getERC20RoyaltyBalance(user3.address, payoutToken.address);

    const sentUserRoyaltyBalance = await nftRoyaltySale
      .connect(provider)
      .getERC20RoyaltyBalance(user5.address, payoutToken.address);

    await nftRoyaltySale
      .connect(user2)
      .withdrawERC20Royalty(
        user2RoyaltyBal,
        user2.address,
        payoutToken.address
      );
    await nftRoyaltySale
      .connect(user3)
      .withdrawERC20Royalty(
        user3RoyaltyBal,
        user3.address,
        payoutToken.address
      );

    await nftRoyaltySale
      .connect(user5)
      .withdrawERC20Royalty(
        sentUserRoyaltyBalance,
        user5.address,
        payoutToken.address
      );

    await expect(
      nftRoyaltySale
        .connect(user4)
        .withdrawERC20Royalty(
          user2RoyaltyBal,
          user4.address,
          payoutToken.address
        )
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
  const creatorName = "testArtiste";
  let linkToken;

  let picardyHub;
  let nftRoyaltySaleFactory;
  let nftRoyaltySaleAddress;
  let nftRoyaltySale;
  let tokenContract;
  let nftRoyaltyAddress;
  let nftBase;
  let nftRoyaltyImpAddress;

  beforeEach(async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    let details = {
      maxSupply: maxSupply,
      maxMintAmount: maxMintAmount,
      cost: formatedCost,
      percentage: percentage,
      name: name,
      symbol: symbol,
      initBaseURI: initBaseURI,
      creatorName: creatorName,
      creator: user1.address,
    };

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
      await nftRoyaltySaleFactory.getNftRoyaltySaleAddress(creatorName, name);

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
