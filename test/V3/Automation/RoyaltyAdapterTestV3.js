const { assert, expect } = require("chai");
const chai = require("chai");
const { ethers } = require("hardhat");
chai.use(require("chai-as-promised"));

describe("PicardyRoyaltyAdapter", function () {
  let picardyHub;
  let royaltyAdapter;

  const maxSupply = 100;
  const maxMintAmount = 20;
  const formatedCost = ethers.utils.parseUnits("1", "ether"); // 1 eth
  const percentage = 10;
  const name = "testToken";
  const symbol = "TST";
  const initBaseURI = "https://test.com/";
  const creatorName = "creator";

  let linkToken;
  let jobId = "42b90f5bf8b940029fed6330f7036f01";
  let oracleAddress = "0x7E0ffaca8352CbB93c099C08b9aD7B4bE9f790Ec";
  let nftRoyaltyImpAddress;
  let nftRoyaltySaleFactory;
  let nftRoyaltySaleAddress;
  let nftRoyaltyAdapter;
  let payMaster;

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

    let ticker = "ETH";

    const LinkToken = await ethers.getContractFactory("MocLink");
    tokenContract = await LinkToken.deploy();
    linkToken = tokenContract.address;

    const PicardyHub = await ethers.getContractFactory("PicardyHub");
    picardyHub = await PicardyHub.deploy();

    const PayMaster = await ethers.getContractFactory("PayMasterV3");
    payMaster = await PayMaster.deploy(picardyHub.address);

    const NftRoyaltySaleImpl = await hre.ethers.getContractFactory(
      "NftRoyaltySaleV3"
    );

    const nftRoyaltyImp = await NftRoyaltySaleImpl.deploy();
    await nftRoyaltyImp.deployed();
    nftRoyaltyImpAddress = nftRoyaltyImp.address;

    const NftRoyaltySaleFactory = await ethers.getContractFactory(
      "NftRoyaltySaleFactoryV3"
    );

    nftRoyaltySaleFactory = await NftRoyaltySaleFactory.deploy(
      picardyHub.address,
      linkToken,
      nftRoyaltyImpAddress
    );

    const tx1 = await nftRoyaltySaleFactory
      .connect(user1)
      .createNftRoyalty(details);

    nftRoyaltySaleAddress =
      await nftRoyaltySaleFactory.getNftRoyaltySaleAddress(creatorName, name);

    const RoyaltyAdapterV2 = await ethers.getContractFactory(
      "RoyaltyAdapterV3"
    );

    royaltyAdapter = await RoyaltyAdapterV2.deploy(
      linkToken,
      payMaster.address,
      picardyHub.address
    );

    await tokenContract.mint(
      ethers.utils.parseUnits("100", "ether"),
      royaltyAdapter.address
    );
  });

  it("only hubAdmin should withdraw link", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      royaltyAdapter.connect(user2).withdrawLink()
    ).to.be.rejectedWith(Error);

    const linkBalance = await tokenContract.balanceOf(royaltyAdapter.address);

    await royaltyAdapter.connect(hubAdmin).withdrawLink();

    const ownersLinkBalance = await tokenContract.balanceOf(hubAdmin.address);

    expect(ownersLinkBalance).to.equal(linkBalance);
  });

  it("only hubAdmin should withdraw ETH", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      royaltyAdapter.connect(user2).withdrawBalance()
    ).to.be.rejectedWith(Error);

    await user2.sendTransaction({
      to: royaltyAdapter.address,
      value: ethers.utils.parseUnits("50", "ether"),
    });

    await royaltyAdapter.connect(hubAdmin).withdrawBalance();
  });

  it("only hubAdmin should update Oracle Payment", async () => {
    const [hubAdmin, royaltyAddress, user1, user2, user3] =
      await ethers.getSigners();

    await expect(
      royaltyAdapter
        .connect(user2)
        .updateOraclePayment(ethers.utils.parseUnits("1", "ether"))
    ).to.be.rejectedWith(Error);

    await royaltyAdapter
      .connect(hubAdmin)
      .updateOraclePayment(ethers.utils.parseUnits("1", "ether"));
  });
}); // end describe
