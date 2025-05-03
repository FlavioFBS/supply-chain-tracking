// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/core/AgreementContract.sol";
import "../src/core/ManufacturerRegistry.sol";
import "../src/core/RetailerRegistry.sol";

contract AgreementContractTest is Test {
    AgreementContractManufacturerRetailer public agreementContract;
    ManufacturerRegistry public manufacturerRegistry;
    RetailerRegistry public retailerRegistry;

    // Test addresses
    address public manufacturerAdmin = address(0x123);
    address public retailerAdmin = address(0x456);
    address public unauthorizedUser = address(0x789);

    // Test data
    bytes32 public manufacturerId = keccak256("manufacturer1");
    bytes32 public retailerId = keccak256("retailer1");
    bytes32 public agreementId = keccak256("agreement1");
    string public termsHash = "QmTestHash";
    uint256 public startDate;
    uint256 public endDate;

    event AgreementSigned(bytes32 agreementId, address signer);

    function setUp() public {
        // Deploy contracts
        manufacturerRegistry = new ManufacturerRegistry();
        retailerRegistry = new RetailerRegistry();
        agreementContract =
            new AgreementContractManufacturerRetailer(address(manufacturerRegistry), address(retailerRegistry));

        // Setup dates
        startDate = block.timestamp + 1 days;
        endDate = block.timestamp + 30 days;

        // Mock admin validations
        vm.mockCall(
            address(manufacturerRegistry),
            abi.encodeWithSelector(
                manufacturerRegistry.isAdminByManufacturer.selector, manufacturerAdmin, manufacturerId
            ),
            abi.encode(true)
        );
        vm.mockCall(
            address(retailerRegistry),
            abi.encodeWithSelector(retailerRegistry.isAdminByRetailer.selector, retailerAdmin, retailerId),
            abi.encode(true)
        );
    }

    function testCreateAgreementSuccess() public {
        agreementContract.createAgreement(
            agreementId, manufacturerId, retailerId, termsHash, startDate, endDate, manufacturerAdmin, retailerAdmin
        );

        (
            bytes32 _agreementId,
            bytes32 _manufacturerId,
            bytes32 _retailerId,
            string memory _termsHash,
            uint256 _startDate,
            uint256 _endDate,
            address _manufacturerAdminCreateAgreement,
            address _retailerAdminCreateAgreement,
            bool _signedByManufacturer,
            bool _signedByRetailer,
            address _manufacturerAdminSignAgreement,
            address _retailerAdminSignAgreement
        ) = agreementContract.agreements(agreementId);

        assertEq(_agreementId, agreementId);
        assertEq(_manufacturerId, manufacturerId);
        assertEq(_retailerId, retailerId);
        assertEq(_termsHash, termsHash);
        assertEq(_startDate, startDate);
        assertEq(_endDate, endDate);
        assertEq(_manufacturerAdminCreateAgreement, manufacturerAdmin);
        assertEq(_retailerAdminCreateAgreement, retailerAdmin);
        assertFalse(_signedByManufacturer);
        assertFalse(_signedByRetailer);
    }

    function testCreateAgreementFailsIfExists() public {
        agreementContract.createAgreement(
            agreementId, manufacturerId, retailerId, termsHash, startDate, endDate, manufacturerAdmin, retailerAdmin
        );

        vm.expectRevert("Agreement already exists");
        agreementContract.createAgreement(
            agreementId, manufacturerId, retailerId, termsHash, startDate, endDate, manufacturerAdmin, retailerAdmin
        );
    }

    function testCreateAgreementFailsWithEmptyIds() public {
        bytes32 emptyId;
        vm.expectRevert("Empty manufacturerId or retailerId");
        agreementContract.createAgreement(
            agreementId, emptyId, retailerId, termsHash, startDate, endDate, manufacturerAdmin, retailerAdmin
        );
    }

    function testCreateAgreementFailsWithEmptyTermsHash() public {
        vm.expectRevert("Empty termsHash");
        agreementContract.createAgreement(
            agreementId, manufacturerId, retailerId, "", startDate, endDate, manufacturerAdmin, retailerAdmin
        );
    }

    function testCreateAgreementFailsWithInvalidDates() public {
        vm.expectRevert("Invalid start or end date");
        agreementContract.createAgreement(
            agreementId,
            manufacturerId,
            retailerId,
            termsHash,
            block.timestamp - 1,
            endDate,
            manufacturerAdmin,
            retailerAdmin
        );

        vm.expectRevert("Invalid start or end date");
        agreementContract.createAgreement(
            agreementId,
            manufacturerId,
            retailerId,
            termsHash,
            startDate,
            startDate - 1,
            manufacturerAdmin,
            retailerAdmin
        );
    }

    function testCreateAgreementFailsWithInvalidAdmins() public {
        // Mock manufacturer admin validation to fail
        vm.mockCall(
            address(manufacturerRegistry),
            abi.encodeWithSelector(
                manufacturerRegistry.isAdminByManufacturer.selector, manufacturerAdmin, manufacturerId
            ),
            abi.encode(false)
        );

        vm.expectRevert("Manufacturer admin not active");
        agreementContract.createAgreement(
            agreementId, manufacturerId, retailerId, termsHash, startDate, endDate, manufacturerAdmin, retailerAdmin
        );
    }

    function testSignAgreementSuccess() public {
        // Create agreement first
        agreementContract.createAgreement(
            agreementId, manufacturerId, retailerId, termsHash, startDate, endDate, manufacturerAdmin, retailerAdmin
        );

        // Manufacturer signs
        vm.prank(manufacturerAdmin);
        vm.expectEmit(true, true, true, true);
        emit AgreementSigned(agreementId, manufacturerAdmin);
        agreementContract.signAgreement(agreementId);

        (
            bytes32 _agreementId,
            bytes32 _manufacturerId,
            bytes32 _retailerId,
            string memory _termsHash,
            uint256 _startDate,
            uint256 _endDate,
            address _manufacturerAdminCreateAgreement,
            address _retailerAdminCreateAgreement,
            bool _signedByManufacturer,
            bool _signedByRetailer,
            address _manufacturerAdminSignAgreement,
            address _retailerAdminSignAgreement
        ) = agreementContract.agreements(agreementId);
        assertTrue(_signedByManufacturer);
        assertEq(_manufacturerAdminSignAgreement, manufacturerAdmin);

        // Retailer signs
        vm.prank(retailerAdmin);
        vm.expectEmit(true, true, true, true);
        emit AgreementSigned(agreementId, retailerAdmin);
        agreementContract.signAgreement(agreementId);

        (
            bytes32 __agreementId,
            bytes32 __manufacturerId,
            bytes32 __retailerId,
            string memory __termsHash,
            uint256 __startDate,
            uint256 __endDate,
            address __manufacturerAdminCreateAgreement,
            address __retailerAdminCreateAgreement,
            bool __signedByManufacturer,
            bool __signedByRetailer,
            address __manufacturerAdminSignAgreement,
            address __retailerAdminSignAgreement
        ) = agreementContract.agreements(agreementId);

        assertTrue(__signedByRetailer);
        assertEq(__retailerAdminSignAgreement, retailerAdmin);
    }

    function testSignAgreementFailsIfNotExists() public {
        vm.prank(manufacturerAdmin);
        vm.expectRevert("Agreement does not exist");
        agreementContract.signAgreement(agreementId);
    }

    function testSignAgreementFailsIfAlreadySigned() public {
        // Create and sign agreement
        agreementContract.createAgreement(
            agreementId, manufacturerId, retailerId, termsHash, startDate, endDate, manufacturerAdmin, retailerAdmin
        );

        vm.prank(manufacturerAdmin);
        agreementContract.signAgreement(agreementId);

        vm.expectRevert("Sender already signed the agreement");
        vm.prank(manufacturerAdmin);
        agreementContract.signAgreement(agreementId);
    }

    function testSignAgreementFailsIfUnauthorized() public {
        // Create agreement
        agreementContract.createAgreement(
            agreementId, manufacturerId, retailerId, termsHash, startDate, endDate, manufacturerAdmin, retailerAdmin
        );

        // Mock both admin validations to fail
        vm.mockCall(
            address(manufacturerRegistry),
            abi.encodeWithSelector(
                manufacturerRegistry.isAdminByManufacturer.selector, unauthorizedUser, manufacturerId
            ),
            abi.encode(false)
        );
        vm.mockCall(
            address(retailerRegistry),
            abi.encodeWithSelector(retailerRegistry.isAdminByRetailer.selector, unauthorizedUser, retailerId),
            abi.encode(false)
        );

        vm.prank(unauthorizedUser);
        vm.expectRevert("Sender is not an active admin");
        agreementContract.signAgreement(agreementId);
    }

    function testIsAgreementActive() public {
        // Create and sign agreement
        agreementContract.createAgreement(
            agreementId, manufacturerId, retailerId, termsHash, startDate, endDate, manufacturerAdmin, retailerAdmin
        );

        // Not active before both parties sign
        assertFalse(agreementContract.isAgreementActive(agreementId));

        // Manufacturer signs
        vm.prank(manufacturerAdmin);
        agreementContract.signAgreement(agreementId);
        assertFalse(agreementContract.isAgreementActive(agreementId));

        // Retailer signs
        vm.prank(retailerAdmin);
        agreementContract.signAgreement(agreementId);

        // Not active before start date
        assertFalse(agreementContract.isAgreementActive(agreementId));

        // Active during valid period
        vm.warp(startDate + 1);
        assertTrue(agreementContract.isAgreementActive(agreementId));

        // Not active after end date
        vm.warp(endDate + 1);
        assertFalse(agreementContract.isAgreementActive(agreementId));
    }
}
