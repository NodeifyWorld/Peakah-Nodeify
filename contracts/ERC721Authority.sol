// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721Authority is Ownable {
    mapping(address => bool) internal _whitelist;

    function addToWhitelist(address account) public onlyOwner {
        _whitelist[account] = true;
    }

    function removeFromWhitelist(address account) public onlyOwner {
        _whitelist[account] = false;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }
}
