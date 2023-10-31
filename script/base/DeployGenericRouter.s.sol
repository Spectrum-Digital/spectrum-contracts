// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {GenericRouter} from "../../src/GenericRouter.sol";

contract DeployGenericRouter is Script {
    function run() public returns (address router) {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");

        // Start broadcasting the transaction to the network.
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the router
        router = address(new GenericRouter());

        // Stop broadcasting the transaction to the network.
        vm.stopBroadcast();
    }
}
