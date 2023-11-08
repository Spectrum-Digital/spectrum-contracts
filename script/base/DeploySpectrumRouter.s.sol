// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {SpectrumRouter} from "../../src/SpectrumRouter.sol";

contract DeploySpectrumRouter is Script {
    function run() public returns (address router) {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        uint256 deployerPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");

        // Start broadcasting the transaction to the network.
        vm.startBroadcast(deployerPrivateKey);

        address implementation = address(new SpectrumRouter());
        address proxyAdmin = address(new ProxyAdmin());
        address router = address(
            new TransparentUpgradeableProxy(
                implementation,
                proxyAdmin,
                abi.encodeWithSignature("initialize(address)", vm.addr(deployerPrivateKey))
            )
        );

        //         address(
        //     new TransparentUpgradeableProxy(
        //         contracts.factoryImplementation,
        //         contracts.proxyAdmin,
        //         abi.encodeWithSignature("initialize(address)", vm.addr(deployerPrivateKey))
        //     )
        // )

        // Stop broadcasting the transaction to the network.
        vm.stopBroadcast();
    }
}

contract TestUUPS is OwnableUpgradeable, UUPSUpgradeable {
    uint256 public value;

    function initialize(uint256 value_) public initializer {
        value = value_;
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
