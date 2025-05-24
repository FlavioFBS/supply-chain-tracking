// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Roles} from "../access/RolManager.sol";
import {ProductRegistry} from "./ProductRegistry.sol";
import {ProductLocation} from "./ProductLocation.sol";

contract ReceiveProduct is AccessControl {
    ProductRegistry public immutable productRegistry;
    IERC721 public immutable productNFT;
    ProductLocation public immutable productLocation;

    event ProductReceived(uint256 productId, address retailer, uint256 timestamp);

    constructor(address _productRegistry, address _productLocation) {
        productRegistry = ProductRegistry(_productRegistry);
        productNFT = IERC721(productRegistry.productNFT());
        productLocation = ProductLocation(_productLocation);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function markAsReceived(uint256 productId) external onlyRole(Roles.RETAILER_ROLE) {
        // get the current owner of the product
        (,,,,, address currentOwner) = productRegistry.products(productId);

        require(currentOwner != address(0), "Product does not exist");
        require(currentOwner != msg.sender, "Product already received");

        // additional security: Verify that the currentOwner is the owner of the NFT
        require(productNFT.ownerOf(productId) == currentOwner, "Ownership mismatch");

        // update FIRST the state (Checks-Effects-Interactions)
        productRegistry.updateProductOwner(productId, msg.sender);

        // Transfer NFT (the receiver is msg.sender)
        productNFT.safeTransferFrom(currentOwner, msg.sender, productId);

        emit ProductReceived(productId, msg.sender, block.timestamp);
    }

    struct ProductHistory {
        address[] owners;
        ProductLocation.Location[] locations;
    }

    function getProductHistory(uint256 productId) external view returns (ProductHistory memory) {
        // Check if the product exists
        require(productNFT.ownerOf(productId) != address(0), "Product not exist");

        address currentOwner = productRegistry.getProductCurrentOwner(productId);
        address[] memory previousOwners = productRegistry.getProductPreviousOwners(productId);

        address[] memory allOwners = new address[](previousOwners.length + 1);
        for (uint256 i = 0; i < previousOwners.length; i++) {
            allOwners[i] = previousOwners[i];
        }
        allOwners[previousOwners.length] = currentOwner;
        ProductLocation.Location[] memory locations = productLocation.getLocationHistory(productId);

        return ProductHistory(allOwners, locations);
    }
}
