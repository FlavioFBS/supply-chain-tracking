// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {ProductNFT} from "./ProductNFT.sol";
import "../access/RolManager.sol";
import {ManufacturerRegistry} from "./ManufacturerRegistry.sol";
import {AgreementContractManufacturerRetailer} from "./AgreementContract.sol";

contract ProductRegistry is AccessControl {
    ProductNFT public productNFT;
    ManufacturerRegistry public manufacturerRegistry;
    AgreementContractManufacturerRetailer public agreementContract;

    struct Product {
        address manufacturer;
        uint256 timestamp;
        string ipfsHash;
        bytes32 manufacturerId; // Unique identifier for the manufacturer, e.g Ruc or hash of the company name
        bytes32 agreementId; // Unique identifier for the agreement. E.g. hash of the cocatenated manufacturerId and retailerId
        address currentOwner; // manufacturer → transporter → retailer
    }

    mapping(uint256 => Product) public products;

    event ProductRegistered(uint256 productId, address manufacturer, string ipfsHash);

    constructor(
        address _rolesManager,
        address _manufacturerRegistry,
        address _agreementContract
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _rolesManager);
        productNFT = new ProductNFT();
        manufacturerRegistry = ManufacturerRegistry(_manufacturerRegistry);
        agreementContract = AgreementContractManufacturerRetailer(_agreementContract);
    }

    function registerProduct(bytes32 manufacturerId, bytes32 agreementId, string memory _ipfsHash)
        external
        onlyRole(Roles.MANUFACTURER_ROLE)
    {
        require(
            manufacturerRegistry.isAdminByManufacturer(msg.sender, manufacturerId),
            "Not an active manufacturer admin"
        );
        
        require(
            agreementContract.isAgreementActive(agreementId),
            "Not an active Agreement"
        );

        uint256 productId = productNFT.mint(msg.sender);
        require(productId > 0, "Minting failed");
        products[productId] = Product(msg.sender, block.timestamp, _ipfsHash, manufacturerId, agreementId, msg.sender);
        emit ProductRegistered(productId, msg.sender, _ipfsHash);
    }
}
