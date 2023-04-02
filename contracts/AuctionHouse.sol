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
        uint256 endTime;
        address payable highestBidder;
        uint256 highestBid;
        bool hasReceivedBids;
        bool ended;
    }

    uint256 public auctionDuration = 24 hours;
    uint256 public biddingDuration = 18 hours;
    uint256 private nextAuctionStartTime;
    uint256 public auctionCounter;
    mapping(uint256 => Auction) public auctions;
    PeakyBirds public erc721;
    uint256 public defaultStartingPrice;

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
        defaultStartingPrice = 0.1 ether;
    }

    function createAuction() external onlyOwner {
        uint256 tokenId = erc721.currentSupply() + 1;
        erc721.safeMint(address(this), tokenId);

        uint256 auctionId = auctionCounter;
        auctions[auctionId] = Auction({
            tokenAddress: address(erc721),
            tokenId: tokenId,
            seller: payable(msg.sender),
            endTime: block.timestamp + auctionDuration,
            highestBidder: payable(address(0)),
            highestBid: defaultStartingPrice,
            hasReceivedBids: false,
            ended: false
        });
        auctionCounter = auctionCounter + 1;
        emit AuctionCreated(auctionId, tokenId);
    }

    function placeBid(uint256 auctionId) external payable nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(
            block.timestamp <= auction.endTime.sub(biddingDuration),
            "Bidding period has ended"
        );
        require(
            msg.value > auction.highestBid &&
                msg.value >= auction.highestBid.add(defaultStartingPrice),
            "Bid not high enough"
        );

        if (auction.highestBidder != address(0)) {
            auction.highestBidder.transfer(auction.highestBid);
        }

        auction.highestBidder = payable(msg.sender);
        auction.highestBid = msg.value;
        auction.hasReceivedBids = true;
        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setDefaultStartingPrice(
        uint256 newDefaultStartingPrice
    ) external onlyOwner {
        defaultStartingPrice = newDefaultStartingPrice;
    }

    function getTokenInfo(
        uint256 auctionId
    ) external view returns (string memory tokenURI, uint256 tokenId) {
        tokenId = auctions[auctionId].tokenId;
        tokenURI = erc721.tokenURI(tokenId);
    }

    function changeAuctionDuration(
        uint256 _auctionDuration
    ) external onlyOwner {
        auctionDuration = _auctionDuration;
    }

    function changeBiddingDuration(
        uint256 _biddingDuration
    ) external onlyOwner {
        biddingDuration = _biddingDuration;
    }

    function forceEndAuction(uint256 auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];
        require(!auction.ended, "Auction already ended");
        require(block.timestamp > auction.endTime, "Auction still ongoing");
        auction.ended = true;
        if (auction.hasReceivedBids) {
            auction.highestBidder.transfer(auction.highestBid);
            erc721.transferFrom(
                address(this),
                auction.highestBidder,
                auction.tokenId
            );
            emit AuctionEnded(
                auctionId,
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            erc721.transferFrom(address(this), auction.seller, auction.tokenId);
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }
}
