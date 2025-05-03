// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../src/core/ProductRegistry.sol";
import "../src/core/ProductNFT.sol";
import "../src/core/ManufacturerRegistry.sol";
import "../src/core/AgreementContract.sol";
import "../src/core/RetailerRegistry.sol";
import "../src/access/RolManager.sol";

contract ProductRegistryTest is Test {
    event ProductRegistered(uint256 productId, address manufacturer, string ipfsHash);

    ProductRegistry public productRegistry;
    ProductNFT public productNFT;
    ManufacturerRegistry public manufacturerRegistry;
    AgreementContractManufacturerRetailer public agreementContract;
    RetailerRegistry public retailerRegistry;
    
    address public rolesManager = address(0x123);
    address public manufacturer = address(0x456);
    bytes32 public manufacturerId = keccak256("manufacturer1");
    bytes32 public agreementId = keccak256("agreement1");
    address public unauthorizedUser = address(0x789);

    function setUp() public {
        vm.startPrank(rolesManager);
        manufacturerRegistry = new ManufacturerRegistry();
        agreementContract = new AgreementContractManufacturerRetailer(address(manufacturerRegistry), address(retailerRegistry));
        productRegistry = new ProductRegistry(
            rolesManager,
            address(manufacturerRegistry),
            address(agreementContract)
        );
        productNFT = productRegistry.productNFT();
        productRegistry.grantRole(Roles.MANUFACTURER_ROLE, manufacturer);
        vm.stopPrank();
    }

    function testRegisterProductSuccess() public {
        vm.startPrank(manufacturer);
        string memory ipfsHash = "QmTestHash";

        vm.mockCall(
            address(manufacturerRegistry),
            abi.encodeWithSelector(
                ManufacturerRegistry.isAdminByManufacturer.selector,
                manufacturer,
                manufacturerId
            ),
            abi.encode(true)
        );

        vm.mockCall(
            address(agreementContract),
            abi.encodeWithSelector(
                AgreementContractManufacturerRetailer.isAgreementActive.selector,
                agreementId
            ),
            abi.encode(true)
        );

        vm.expectEmit(true, true, true, true);
        emit ProductRegistered(1, manufacturer, ipfsHash);
        productRegistry.registerProduct(manufacturerId, agreementId, ipfsHash);

        (
            address registeredManufacturer,
            uint256 timestamp,
            string memory registeredIpfsHash,
            bytes32 manufacturerId,
            bytes32 agreementId,
            address currentOwner
        ) = productRegistry.products(1);
        assertEq(currentOwner, manufacturer);
        assertEq(manufacturerId, manufacturerId);
        assertEq(agreementId, agreementId);
        assertEq(registeredManufacturer, manufacturer);
        assertEq(registeredIpfsHash, ipfsHash);
        assertTrue(timestamp > 0);
        vm.stopPrank();
    }

    function testRegisterProductUnauthorized() public {
        vm.startPrank(unauthorizedUser);
        string memory ipfsHash = "QmTestHash";
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", unauthorizedUser, Roles.MANUFACTURER_ROLE
            )
        );
        productRegistry.registerProduct(manufacturerId, agreementId, ipfsHash);
        vm.stopPrank();
    }

    function testRegisterProductFailsIfNotManufacturerAdmin() public {
        vm.startPrank(manufacturer);
        string memory ipfsHash = "QmTestHash";

        vm.mockCall(
            address(manufacturerRegistry),
            abi.encodeWithSelector(
                ManufacturerRegistry.isAdminByManufacturer.selector,
                manufacturer,
                manufacturerId
            ),
            abi.encode(false)
        );

        vm.expectRevert(bytes("Not an active manufacturer admin"));
        productRegistry.registerProduct(manufacturerId, agreementId, ipfsHash);
        vm.stopPrank();
    }

    function testRegisterProductFailsIfNotActiveAgreement() public {
        vm.startPrank(manufacturer);
        string memory ipfsHash = "QmTestHash";

        vm.mockCall(
            address(manufacturerRegistry),
            abi.encodeWithSelector(
                ManufacturerRegistry.isAdminByManufacturer.selector,
                manufacturer,
                manufacturerId
            ),
            abi.encode(true)
        );

        vm.mockCall(
            address(manufacturerRegistry),
            abi.encodeWithSelector(
                AgreementContractManufacturerRetailer.isAgreementActive.selector,
                agreementId
            ),
            abi.encode(false)
        );

        vm.expectRevert(bytes("Not an active Agreement"));
        productRegistry.registerProduct(manufacturerId, agreementId, ipfsHash);
        vm.stopPrank();
    }
    
    function testMintFailure() public {
        vm.startPrank(manufacturer);
        string memory ipfsHash = "QmTestHash";

        vm.mockCall(
            address(manufacturerRegistry),
            abi.encodeWithSelector(
                ManufacturerRegistry.isAdminByManufacturer.selector,
                manufacturer,
                manufacturerId
            ),
            abi.encode(true)
        );

        vm.mockCall(
            address(agreementContract),
            abi.encodeWithSelector(
                AgreementContractManufacturerRetailer.isAgreementActive.selector,
                agreementId
            ),
            abi.encode(true)
        );

        vm.mockCall(
            address(productNFT),
            abi.encodeWithSelector(productNFT.mint.selector),
            abi.encode(0)
        );

        vm.expectRevert("Minting failed");
        productRegistry.registerProduct(manufacturerId, agreementId, ipfsHash);
        vm.stopPrank();
    }
}
