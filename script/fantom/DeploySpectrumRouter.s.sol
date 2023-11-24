// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";
import {SpectrumRouter} from "../../src/SpectrumRouter.sol";

contract DeploySpectrumRouter is Script {
    function run() public returns (address owner, address implementation, address proxyAdmin, address router) {
        vm.createSelectFork(vm.rpcUrl("fantom"));
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");

        // Start broadcasting the transaction to the network.
        vm.startBroadcast(deployerPrivateKey);

        // Admin control
        owner = vm.addr(deployerPrivateKey);
        proxyAdmin = address(new ProxyAdmin(owner));

        // Deploy the implementation
        implementation = address(new SpectrumRouter());

        // Deploy the proxy
        router = address(
            new TransparentUpgradeableProxy(implementation, proxyAdmin, abi.encodeWithSignature("initialize(address)", owner))
        );

        // Stop broadcasting the transaction to the network.
        vm.stopBroadcast();
    }
}
