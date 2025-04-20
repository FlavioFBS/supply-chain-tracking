// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../access/RolManager.sol";


contract ProductNFT is ERC721, AccessControl {
    uint256 private _tokenIdCounter;

    constructor() ERC721("SupplyChainProduct", "SCP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Roles.MINTER_ROLE, msg.sender);
    }

    function mint(address to) external onlyRole(Roles.MINTER_ROLE) returns(uint256) {
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;
        _safeMint(to, newTokenId);
        return newTokenId;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
