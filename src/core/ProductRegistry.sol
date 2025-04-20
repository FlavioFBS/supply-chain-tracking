// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import { ProductNFT } from './ProductNFT.sol';
import '../access/RolManager.sol';

contract ProductRegistry is AccessControl{
    ProductNFT public productNFT;

    struct Product {
        address manufacturer;
        uint256 timestamp;
        string ipfsHash;
    }

    mapping(uint256 => Product) public products;

    event ProductRegistered(uint256 productId, address manufacturer, string ipfsHash);

    constructor(address _rolesManager) {
        _grantRole(DEFAULT_ADMIN_ROLE, _rolesManager);
        productNFT = new ProductNFT();
    }

    function registerProduct(string memory _ipfsHash) external onlyRole(Roles.MANUFACTURER_ROLE) {
        uint256 productId = productNFT.mint(msg.sender);
        products[productId] = Product(msg.sender, block.timestamp, _ipfsHash);
        emit ProductRegistered(productId, msg.sender, _ipfsHash);
    }

}