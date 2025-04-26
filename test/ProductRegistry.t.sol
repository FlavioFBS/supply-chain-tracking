// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/core/ProductRegistry.sol";
import "../src/core/ProductNFT.sol";
import "../src/access/RolManager.sol";

contract ProductRegistryTest is Test {
    event ProductRegistered(uint256 productId, address manufacturer, string ipfsHash);

    ProductRegistry public productRegistry;
    ProductNFT public productNFT;
    address public rolesManager = address(0x123);
    address public manufacturer = address(0x456);
    address public unauthorizedUser = address(0x789);

    function setUp() public {
        vm.startPrank(rolesManager);
        productRegistry = new ProductRegistry(rolesManager);
        productNFT = productRegistry.productNFT();
        productRegistry.grantRole(Roles.MANUFACTURER_ROLE, manufacturer);
        vm.stopPrank();
    }

    function testRegisterProductSuccess() public {
        vm.startPrank(manufacturer);
        string memory ipfsHash = "QmTestHash";
        vm.expectEmit(true, true, true, true);
        emit ProductRegistered(1, manufacturer, ipfsHash);
        productRegistry.registerProduct(ipfsHash);

        (address registeredManufacturer, uint256 timestamp, string memory registeredIpfsHash) =
            productRegistry.products(1);
        assertEq(registeredManufacturer, manufacturer);
        assertEq(registeredIpfsHash, ipfsHash);
        assertTrue(timestamp > 0);
        vm.stopPrank();
    }

    function testRegisterProductUnauthorized() public {
        vm.startPrank(unauthorizedUser);
        string memory ipfsHash = "QmTestHash";
        // vm.expectRevert("AccessControl: account is missing role___"); // Mensaje genérico de OpenZeppelin
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector, // Selector del custom error
                unauthorizedUser, // Dirección del usuario no autorizado
                Roles.MANUFACTURER_ROLE // Rol requerido
            )
        );
        productRegistry.registerProduct(ipfsHash);
        vm.stopPrank();
    }

    function testMintFailure() public {
        vm.startPrank(manufacturer);
        string memory ipfsHash = "QmTestHash";

        // Simular fallo en mint
        vm.mockCall(
            address(productNFT),
            abi.encodeWithSelector(productNFT.mint.selector),
            abi.encode(0) // Simula que mint devuelve 0 (fallo)
        );

        vm.expectRevert("Minting failed");
        productRegistry.registerProduct(ipfsHash);
        vm.stopPrank();
    }

    function testProductRegisteredEvent() public {
        vm.startPrank(manufacturer);
        string memory ipfsHash = "QmTestHash";

        vm.expectEmit(true, true, true, true);
        emit ProductRegistered(1, manufacturer, ipfsHash);
        productRegistry.registerProduct(ipfsHash);
        vm.stopPrank();
    }
}
