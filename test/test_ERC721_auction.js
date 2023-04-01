const { expect } = require("chai");
const truffleAssert = require("truffle-assertions");

const ERC721Authority = artifacts.require("ERC721Authority");
const PeakyBirds = artifacts.require("PeakyBirds");
const AuctionHouse = artifacts.require("AuctionHouse");

contract("Smart Contracts", (accounts) => {
  let authority, peakyBirds, auctionHouse;
  const [owner, addr1, addr2, addr3] = accounts;

  beforeEach(async () => {
    authority = await ERC721Authority.new({ from: owner });
    peakyBirds = await PeakyBirds.new(authority.address, { from: owner });
    auctionHouse = await AuctionHouse.new(peakyBirds.address, { from: owner });
  });

  describe("ERC721Authority", function () {
    it("Should add an address to the whitelist", async function () {
      await authority.addToWhitelist(addr1, { from: owner });
      expect(await authority.isWhitelisted(addr1)).to.equal(true);
    });

    it("Should remove an address from the whitelist", async function () {
      await authority.addToWhitelist(addr1, { from: owner });
      await authority.removeFromWhitelist(addr1, { from: owner });
      expect(await authority.isWhitelisted(addr1)).to.equal(false);
    });
  });

  describe("PeakyBirds", function () {
    it("Should mint a new PeakyBirds token", async function () {
      await authority.addToWhitelist(owner, { from: owner });
      const tokenId = 1;
      await peakyBirds.safeMint(owner, tokenId, { from: owner });
      const ownerOfToken = await peakyBirds.ownerOf(tokenId);
      expect(ownerOfToken).to.equal(owner);
    });
  
    it("Should allow the owner to toggle minting pause", async function () {
      await peakyBirds.toggleMintingPause({ from: owner });
      const isMintingPaused = await peakyBirds.mintingPaused();
      expect(isMintingPaused).to.equal(true);
    });
  
    it("Should burn a token", async function () {
        await authority.addToWhitelist(owner, { from: owner });
        const totalSupply = await peakyBirds.totalSupply();
        const tokenId = totalSupply.addn(1);
        await peakyBirds.safeMint(addr1, tokenId, { from: owner });
        await peakyBirds.burn(tokenId, { from: addr1 });
        const ownerAfterBurn = await peakyBirds.ownerOf(tokenId);
        expect(ownerAfterBurn).to.equal("0x0000000000000000000000000000000000000000");
      });
  
    it("Should set the base URI", async function () {
      const newBaseURI = "https://example.com/token/";
      await peakyBirds.setBaseURI(newBaseURI, { from: owner });
      const currentBaseURI = await peakyBirds.baseURI();
      expect(currentBaseURI).to.equal(newBaseURI);
    });
  
    it("Should allow the owner to withdraw funds", async function () {
        const peakyBirds = await PeakyBirds.deployed();
        const auctionHouse = await AuctionHouse.deployed();
        const owner = accounts[0];
        const addr1 = accounts[1];
      
        // Transfer some funds to the PeakyBirds contract
        await web3.eth.sendTransaction({ from: addr1, to: peakyBirds.address, value: web3.utils.toWei("1", "ether") });
      
        // Check owner balances before withdrawal
        const beforeWithdrawBalance = await web3.eth.getBalance(owner);
      
        // Withdraw funds
        await peakyBirds.withdraw({ from: owner });
      
        // Check owner balances after withdrawal
        const afterWithdrawBalance = await web3.eth.getBalance(owner);
      
        // Expect the owner's balance to have increased
        expect(Number(afterWithdrawBalance)).to.be.above(Number(beforeWithdrawBalance));
      });
      
  });
  
  describe("AuctionHouse", function () {
    it("Should create an auction", async function () {
      await authority.addToWhitelist(auctionHouse.address, { from: owner });
      const tx = await auctionHouse.createAuction({ from: addr1 });
      truffleAssert.eventEmitted(tx, "AuctionCreated", (event) => {
        return event.auctionId.toNumber() === 0 && event.tokenId.toNumber() === 1;
      });
    });
  
    it("Should place a bid on an auction", async function () {
      await authority.addToWhitelist(auctionHouse.address, { from: owner });
      await auctionHouse.createAuction({ from: addr1 });
      const bidAmount = web3.utils.toWei("0.3", "ether");
      const tx = await auctionHouse.placeBid(0, { from: addr2, value: bidAmount });
      truffleAssert.eventEmitted(tx, "BidPlaced", (event) => {
        return event.auctionId.toNumber() === 0 && event.bidder === addr2 && event.amount.toString() === bidAmount;
      });
    });
  
    it("Should allow the owner to withdraw funds", async function () {
        const peakyBirds = await PeakyBirds.deployed();
        const auctionHouse = await AuctionHouse.deployed();
        const owner = accounts[0];
        const addr1 = accounts[1];
      
        // Transfer some funds to the AuctionHouse contract
        await web3.eth.sendTransaction({ from: addr1, to: auctionHouse.address, value: web3.utils.toWei("1", "ether") });
      
        // Check owner balances before withdrawal
        const beforeWithdrawBalance = await web3.eth.getBalance(owner);
      
        // Withdraw funds
        await auctionHouse.withdraw({ from: owner });
      
        // Check owner balances after withdrawal
        const afterWithdrawBalance = await web3.eth.getBalance(owner);
      
        // Expect the owner's balance to have increased
        expect(Number(afterWithdrawBalance)).to.be.above(Number(beforeWithdrawBalance));
      });
  
    it("Should set the default starting price", async function ()
    {
        const newDefaultStartingPrice = web3.utils.toWei("0.2", "ether");
        await auctionHouse.setDefaultStartingPrice(newDefaultStartingPrice, { from: owner });
        const currentDefaultStartingPrice = await auctionHouse.defaultStartingPrice();
        expect(currentDefaultStartingPrice.toString()).to.equal(newDefaultStartingPrice);
      });
    
      it("Should get token info for an auction", async function () {
        await authority.addToWhitelist(auctionHouse.address, { from: owner });
        await auctionHouse.createAuction({ from: addr1 });
        const tokenInfo = await auctionHouse.getTokenInfo(0);
        const [tokenURI, tokenId] = [tokenInfo.tokenURI, tokenInfo.tokenId];
        const expectedTokenURI = await peakyBirds.tokenURI(tokenId);
        expect(tokenURI).to.equal(expectedTokenURI);
        expect(tokenId.toNumber()).to.equal(1);
      });
    
      it("Should change the auction duration", async function () {
        const newAuctionDuration = 24 * 60 * 60; // 24 hours in seconds
        await auctionHouse.changeAuctionDuration(newAuctionDuration, { from: owner });
        const currentAuctionDuration = await auctionHouse.auctionDuration();
        expect(currentAuctionDuration.toNumber()).to.equal(newAuctionDuration);
      });
    
      it("Should force end an auction", async function () {
        await authority.addToWhitelist(auctionHouse.address, { from: owner });
        await auctionHouse.createAuction({ from: addr1 });
        const bidAmount = web3.utils.toWei("0.3", "ether");
        await auctionHouse.placeBid(0, { from: addr2, value: bidAmount });
        await auctionHouse.forceEndAuction(0, { from: owner });
        const auction = await auctionHouse.auctions(0);
        expect(auction.ended).to.equal(true);
      });
    });

});
