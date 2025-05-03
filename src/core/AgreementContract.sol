// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ManufacturerRegistry.sol";
import "./RetailerRegistry.sol";

contract AgreementContractManufacturerRetailer is AccessControl {
    ManufacturerRegistry public manufacturerRegistry;
    RetailerRegistry public retailerRegistry;

    struct Agreement {
        bytes32 agreementId;
        bytes32 manufacturerId;
        bytes32 retailerId;
        string termsHash; // IPFS hash of PDF/JSON with legal terms
        uint256 startDate;
        uint256 endDate;
        address manufacturerAdminCreateAgreement;
        address retailerAdminCreateAgreement;
        bool signedByManufacturer;
        bool signedByRetailer;
        address manufacturerAdminSignAgreement;
        address retailerAdminSignAgreement;
    }

    mapping(bytes32 => Agreement) public agreements;

    event AgreementSigned(bytes32 agreementId, address signer);

    constructor(address _manufacturerRegistry, address _retailerRegistry) {
        manufacturerRegistry = ManufacturerRegistry(_manufacturerRegistry);
        retailerRegistry = RetailerRegistry(_retailerRegistry);
    }

    function createAgreement(
        bytes32 agreementId, // Unique identifier for the agreement. E.g. hash of the cocatenated manufacturerId + retailerId + agreementName
        bytes32 manufacturerId,
        bytes32 retailerId,
        string calldata termsHash,
        uint256 startDate,
        uint256 endDate,
        address manufacturerAdmin,
        address retailerAdmin
    ) external {
        require(agreements[agreementId].agreementId == bytes32(0), "Agreement already exists");
        require(manufacturerId != bytes32(0) && retailerId != bytes32(0), "Empty manufacturerId or retailerId");
        require(bytes(termsHash).length > 0, "Empty termsHash");
        require(startDate > block.timestamp && endDate > startDate, "Invalid start or end date");
        
        // check if the manufacturerAdmiin and retailerAdmin are active admins of the manufacturer and retailer
        require(
            manufacturerRegistry.isAdminByManufacturer(manufacturerAdmin, manufacturerId),
            "Manufacturer admin not active"
        );
        require(retailerRegistry.isAdminByRetailer(retailerAdmin, retailerId), "Not active an retailer admin");

        agreements[agreementId] = Agreement(
            agreementId,
            manufacturerId,
            retailerId,
            termsHash,
            startDate,
            endDate,
            manufacturerAdmin,
            retailerAdmin,
            false,
            false,
            address(0),
            address(0)
        );
    }

    function signAgreement(bytes32 agreementId) external {
        Agreement storage agreement = agreements[agreementId];
        require(agreement.agreementId != bytes32(0), "Agreement does not exist");
        require(
            agreement.signedByManufacturer == false || agreement.signedByRetailer == false,
            "Agreement already signed by both parties"
        );
        // check if the agreement was signed by one of the parties, the other party must to be different address
        require(
            msg.sender != agreement.manufacturerAdminSignAgreement && msg.sender != agreement.retailerAdminSignAgreement,
            "Sender already signed the agreement"
        );
        // check if the sender is an active admin of the manufacturer or retailer
        require(
            manufacturerRegistry.isAdminByManufacturer(msg.sender, agreement.manufacturerId)
                || retailerRegistry.isAdminByRetailer(msg.sender, agreement.retailerId),
            "Sender is not an active admin"
        );

        if (manufacturerRegistry.isAdminByManufacturer(msg.sender, agreement.manufacturerId)) {
            agreement.signedByManufacturer = true;
            agreement.manufacturerAdminSignAgreement = msg.sender;
        }
        if (retailerRegistry.isAdminByRetailer(msg.sender, agreement.retailerId)) {
            agreement.signedByRetailer = true;
            agreement.retailerAdminSignAgreement = msg.sender;
        }

        emit AgreementSigned(agreementId, msg.sender);
    }

    function isAgreementActive(bytes32 agreementId) public view returns (bool) {
        Agreement memory agreement = agreements[agreementId];
        return agreement.signedByManufacturer && agreement.signedByRetailer && block.timestamp >= agreement.startDate
            && block.timestamp <= agreement.endDate;
    }
}
