// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from 'forge-std/Script.sol';
import {SupplyChain} from "../src/SupplyChain.sol";

contract CounterScript is Script {
    SupplyChain public supplyChain;


    function run() public {
        vm.startBroadcast();

        supplyChain = new SupplyChain();

        vm.stopBroadcast();
    }
}
