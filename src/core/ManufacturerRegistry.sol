// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "forge-std/Test.sol";

import "../access/RolManager.sol";

contract ManufacturerRegistry is AccessControl {
    struct Manufacturer {
        bytes32 manufacturerId; // Unique identifier for the manufacturer, e.g Ruc or hash of the company name
        string ipfsHash; // Metadata: name, address, etc.
        mapping(address => bool) activeAdmins;
    }

    mapping(bytes32 => Manufacturer) public manufacturers;

    event ManufacturerRegistered(bytes32 manufacturerId, string ipfsHash);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function registerManufacturer(bytes32 manufacturerId, string calldata ipfsHash)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(manufacturers[manufacturerId].manufacturerId == bytes32(0), "Manufacturer already registered");
        require(bytes(ipfsHash).length > 0, "Empty IPFS-Hash");
        require(manufacturerId != bytes32(0), "Empty manufacturerId");

        Manufacturer storage manufacturer = manufacturers[manufacturerId];
        manufacturer.manufacturerId = manufacturerId;
        manufacturer.ipfsHash = ipfsHash;

        emit ManufacturerRegistered(manufacturerId, ipfsHash);
    }

    function setAdminByManufacturer(address admin, bytes32 manufacturerId, bool isActive)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(manufacturers[manufacturerId].manufacturerId != bytes32(0), "Manufacturer not registered");
        manufacturers[manufacturerId].activeAdmins[admin] = isActive;
    }

    function isAdminByManufacturer(address admin, bytes32 manufacturerId) external view returns (bool) {
        console.log("isAdminByManufacturer-chech");
        return manufacturers[manufacturerId].activeAdmins[admin];
    }
}
