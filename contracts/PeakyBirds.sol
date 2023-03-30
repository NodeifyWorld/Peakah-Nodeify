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

    constructor(address authorityAddress) ERC721("PeakyBirds", "PB") {
        _tokenCounter = 0;
        authority = ERC721Authority(authorityAddress);
        mintingPaused = false;
    }

    function safeMint(address to, string memory tokenURI) public {
        require(!mintingPaused, "Minting is currently paused");
        require(
            authority.isWhitelisted(msg.sender) || msg.sender == owner(),
            "Not allowed to mint"
        );
        _safeMint(to, _tokenCounter);
        _setTokenURI(_tokenCounter, tokenURI);
        _tokenCounter++;
    }

    // Function to toggle mintingPaused state
    function toggleMintingPause() public onlyOwner {
        mintingPaused = !mintingPaused;
    }
}
