// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {Roles} from "../access/RolManager.sol";

contract ProductLocation is AccessControl {
    struct Location {
        int32 longitude; // Eg: -77.0428 * 10^6 (precition without floats)
        int32 latitude; // Eg: -12.0464 * 10^6
        uint256 timestamp;
    }

    mapping(uint256 => Location[]) public locationHistory;

    event LocationUpdated(uint256 productId, int32 longitude, int32 latitude, uint256 timestamp);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function updateLocation(uint256 productId, int32 longitude, int32 latitude) external onlyRole(Roles.CARRIER_ROLE) {
        locationHistory[productId].push(Location(longitude, latitude, block.timestamp));
        emit LocationUpdated(productId, longitude, latitude, block.timestamp);
    }

    // Get historial of locations
    function getLocationHistory(uint256 productId) external view returns (Location[] memory) {
        return locationHistory[productId];
    }
}
