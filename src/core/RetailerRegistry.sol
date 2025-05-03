// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../access/RolManager.sol";

contract RetailerRegistry is AccessControl {
    struct Retailer {
        bytes32 retailerId; // Unique identifier for the retailer, e.g Ruc or hash of the company name
        string ipfsHash; // Metadata: name, address, etc.
        mapping(address => bool) activeAdmins;
    }

    mapping(bytes32 => Retailer) public retailers;

    event RetailerRegistered(bytes32 retailerId, string ipfsHash);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function registerRetailer(bytes32 retailerId, string calldata ipfsHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(retailers[retailerId].retailerId == bytes32(0), "Retailer already registered");
        require(bytes(ipfsHash).length > 0, "Empty IPFS-Hash");
        require(retailerId != bytes32(0), "Empty retailerId");

        Retailer storage retailer = retailers[retailerId];
        retailer.retailerId = retailerId;
        retailer.ipfsHash = ipfsHash;

        emit RetailerRegistered(retailerId, ipfsHash);
    }

    function setAdminByRetailer(address admin, bytes32 retailerId, bool isActive)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(retailers[retailerId].retailerId != bytes32(0), "Retailer not registered");
        retailers[retailerId].activeAdmins[admin] = isActive;
    }

    function isAdminByRetailer(address admin, bytes32 retailerId) external view returns (bool) {
        return retailers[retailerId].activeAdmins[admin];
    }
}
