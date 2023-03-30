// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Authority.sol";

contract PeakyBirds is ERC721URIStorage, Ownable {
    uint256 private _tokenCounter;
    ERC721Authority public authority;
    bool public mintingPaused;
    string public baseURI = "";
    uint256 public maxSupply;
    uint256 public currentSupply;
    uint256 public maxMintedByOwner;
    uint256 public mintedCountByOwner;

    constructor(address authorityAddress) ERC721("PeakyBirds", "PB") {
        _tokenCounter = 0;
        authority = ERC721Authority(authorityAddress);
        mintingPaused = false;
        maxSupply = 6174;
        currentSupply = 0;
        maxMintedByOwner = 300;
        mintedCountByOwner = 0;
    }

    function safeMint(address to, string memory tokenURI) public {
        require(!mintingPaused, "Minting is currently paused");
        require(
            authority.isWhitelisted(msg.sender) || msg.sender == owner(),
            "Not allowed to mint"
        );
        require(currentSupply < maxSupply, "Max supply reached");
        _safeMint(to, _tokenCounter);
        _setTokenURI(_tokenCounter, tokenURI);
        currentSupply = currentSupply + 1;
        _tokenCounter++;
    }

    function DevMint(address to, uint256 tokenId) public onlyOwner {
        require(
            mintedCountByOwner < maxMintedByOwner,
            "Max minted by owner reached"
        );

        _mint(to, tokenId);
        mintedCountByOwner = mintedCountByOwner + 1;
    }

    // Function to toggle mintingPaused state
    function toggleMintingPause() public onlyOwner {
        mintingPaused = !mintingPaused;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
