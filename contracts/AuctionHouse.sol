// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PeakyBirds.sol";

contract AuctionHouse is ERC721Holder, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Auction {
        address tokenAddress;
        uint256 tokenId;
        address payable seller;
        uint256 startingPrice;
        uint256 endTime;
        address payable highestBidder;
        uint256 highestBid;
        bool ended;
    }

    uint256 public auctionDuration = 18 hours;
    uint256 private nextAuctionStartTime;
    uint256 public auctionCounter;
    mapping(uint256 => Auction) public auctions;
    PeakyBirds public erc721;

    event AuctionCreated(uint256 indexed auctionId, uint256 tokenId);
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount
    );
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 amount
    );

    constructor(address erc721Address) {
        erc721 = PeakyBirds(erc721Address);
        nextAuctionStartTime = block.timestamp;
        auctionCounter = 0;
    }

    function createAuction(uint256 tokenId, uint256 startingPrice) external {
        require(
            block.timestamp >= nextAuctionStartTime,
            "Auction not allowed yet"
        );
        require(
            erc721.getApproved(tokenId) == address(this) ||
                erc721.isApprovedForAll(msg.sender, address(this)),
            "Not approved"
        );

        // Automatically end the previous auction and transfer the NFT to the highest bidder
        if (auctionCounter > 0) {
            Auction storage previousAuction = auctions[auctionCounter - 1];
            require(
                block.timestamp >= previousAuction.endTime,
                "Previous auction has not ended yet"
            );
            require(
                !previousAuction.ended,
                "Previous auction has already ended"
            );

            previousAuction.ended = true;
            previousAuction.seller.transfer(previousAuction.highestBid);
            IERC721(previousAuction.tokenAddress).safeTransferFrom(
                address(this),
                previousAuction.highestBidder,
                previousAuction.tokenId
            );
            emit AuctionEnded(
                auctionCounter - 1,
                previousAuction.highestBidder,
                previousAuction.highestBid
            );
        }

        erc721.safeTransferFrom(msg.sender, address(this), tokenId);
        uint256 auctionId = auctionCounter;
        auctions[auctionId] = Auction({
            tokenAddress: address(erc721),
            tokenId: tokenId,
            seller: payable(msg.sender),
            startingPrice: startingPrice,
            endTime: block.timestamp + auctionDuration,
            highestBidder: payable(address(0)),
            highestBid: 0,
            ended: false
        });
        auctionCounter = auctionCounter + 1;
        nextAuctionStartTime = block.timestamp + auctionDuration;
        emit AuctionCreated(auctionId, tokenId);
    }

    function placeBid(uint256 auctionId) external payable nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp <= auction.endTime, "Auction has ended");
        require(
            msg.value > auction.highestBid &&
                msg.value >= auction.startingPrice,
            "Bid not high enough"
        );

        if (auction.highestBidder != address(0)) {
            auction.highestBidder.transfer(auction.highestBid);
        }

        auction.highestBidder = payable(msg.sender);
        auction.highestBid = msg.value;
        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setStartingPrice(
        uint256 auctionId,
        uint256 startingPrice
    ) external onlyOwner {
        auctions[auctionId].startingPrice = startingPrice;
    }

    function getTokenInfo(
        uint256 auctionId
    ) external view returns (string memory tokenURI, uint256 tokenId) {
        tokenId = auctions[auctionId].tokenId;
        tokenURI = erc721.tokenURI(tokenId);
    }
}
