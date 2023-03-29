const MyERC721 = artifacts.require("MyERC721");
const ERC721Authority = artifacts.require("ERC721Authority");
const AuctionHouse = artifacts.require("AuctionHouse");

module.exports = async (deployer) => {
  await deployer.deploy(ERC721Authority);
  const erc721Authority = await ERC721Authority.deployed();

  await deployer.deploy(MyERC721, ERC721Authority.address);
  const myERC721 = await MyERC721.deployed();

  await deployer.deploy(AuctionHouse, MyERC721.address);
  const auctionHouse = await AuctionHouse.deployed();
};

