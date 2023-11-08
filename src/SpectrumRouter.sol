// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IPair} from "./interfaces/IPair.sol";
import {ISpectrumRouter} from "./interfaces/ISpectrumRouter.sol";

contract SpectrumRouter is ISpectrumRouter, Ownable2StepUpgradeable {
    /**
     * @dev Initialize the contract.
     * @param owner The address of the owner of the contract.
     */
    function initialize(address owner) public initializer {
        if (owner == address(0)) revert VaultFactory__InvalidOwner();
        __Ownable2Step_init();
        _transferOwnership(owner);
    }

    function getReserves(address tokenIn, ReservesHop[] calldata hops) public view returns (address token, bytes[] memory results) {
        uint256 length = hops.length;

        results = new bytes[](length);
        for (uint256 i; i < length; i++) {
            ReservesHop memory hop = hops[i];

            // Call the pair with the payload.
            (bool success, bytes memory callResult) = hop.pair.staticcall(hop.data);
            if (!success) revert SpectrumRouter__GetReservesCallFailure();

            // We're not going to decode the result, because it may differ per AMM.
            results[i] = callResult;
        }

        return (tokenIn, results);
    }

    function getAmountsOut(address tokenIn, AmountsOutHop[] calldata hops) public view returns (address token, uint256 amountOut) {
        uint256 length = hops.length;

        for (uint256 i; i < length; i++) {
            AmountsOutHop memory hop = hops[i];

            // Each payload consists of the amountIn + the path, thus
            // we need to replace the amountIn with the previous result.
            bytes memory data = i == 0 ? hop.data : replaceAmountsIn(hop.data, amountOut);

            // Call the router with the payload.
            (bool success, bytes memory callResult) = hop.router.staticcall(data);
            if (!success) revert SpectrumRouter__GetAmountsOutCallFailure();

            // Decode the result.
            uint256[] memory amounts = abi.decode(callResult, (uint256[]));
            if (amounts.length == 0) revert SpectrumRouter__GetAmountsOutParseFailure();
            amountOut = amounts[amounts.length - 1];
        }

        return (tokenIn, amountOut);
    }

    function replaceAmountsIn(bytes memory data, uint256 amountIn) internal pure returns (bytes memory) {
        // 0xd06ca61f
        // 0000000000000000000000000000000000000000000000000de0b6b3a7640000 -> 1 ether
        // 0000000000000000000000000000000000000000000000000000000000000040
        // 0000000000000000000000000000000000000000000000000000000000000002
        // 000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
        // 000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

        bytes memory result;
        assembly {
            result := data
            mstore(add(result, 36), amountIn)
        }
        return result;
    }
}
