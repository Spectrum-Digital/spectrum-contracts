// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IPair} from "./interfaces/IPair.sol";
import {ISpectrumRouter, PoolRequestCandidateResult, PoolRequestLeg, AmountsOutHop} from "./interfaces/ISpectrumRouter.sol";

contract SpectrumRouter is ISpectrumRouter, Ownable2StepUpgradeable {
    /**
     * @dev Initialize the contract.
     * @param owner The address of the owner of the contract.
     */
    function initialize(address owner) public initializer {
        if (owner == address(0)) revert Initialize__InvalidOwner();
        __Ownable2Step_init();
        _transferOwnership(owner);
    }

    function getAmountsOutCandidates(AmountsOutHop[][] calldata candidates) external view returns (uint256[] memory amountOut) {
        uint256 length = candidates.length;

        amountOut = new uint256[](length);
        for (uint256 i; i < length; i++) {
            uint256 result = getAmountsOut(candidates[i]);
            amountOut[i] = result;
        }
    }

    function getAmountsOut(AmountsOutHop[] calldata hops) public view returns (uint256 amountOut) {
        uint256 length = hops.length;

        for (uint256 i; i < length; i++) {
            AmountsOutHop memory hop = hops[i];

            // Each payload consists of the amountIn + the path, thus
            // we need to replace the amountIn with the previous result.
            bytes memory data = i == 0 ? hop.data : replaceAmountsIn(hop.data, amountOut);

            // Call the router with the payload.
            (bool success, bytes memory callResult) = hop.router.staticcall(data);
            if (!success) revert GetAmountsOut__CallFailure();

            // Decode the result.
            uint256[] memory amounts = abi.decode(callResult, (uint256[]));
            if (amounts.length == 0) revert GetAmountsOut__ParseFailure();
            amountOut = amounts[amounts.length - 1];
        }
    }

    function getPoolRequestsCandidates(
        PoolRequestLeg[][] calldata candidates
    ) external view returns (PoolRequestCandidateResult[] memory result) {
        uint256 length = candidates.length;

        result = new PoolRequestCandidateResult[](length);
        for (uint256 i; i < length; i++) {
            (bytes[] memory results, address[] memory tokens0) = getPoolRequests(candidates[i]);
            result[i] = PoolRequestCandidateResult({results: results, tokens0: tokens0});
        }
    }

    function getPoolRequests(PoolRequestLeg[] calldata legs) public view returns (bytes[] memory results, address[] memory tokens0) {
        uint256 length = legs.length;

        results = new bytes[](length);
        tokens0 = new address[](length);
        for (uint256 i; i < length; i++) {
            PoolRequestLeg memory leg = legs[i];

            // Now retrieve the pair for the given set of tokens.
            (bool pairSuccess, bytes memory pairResult) = leg.factory.staticcall(leg.getPairCalldata);
            if (!pairSuccess) revert GetPoolData__PairCallFailure();
            address pair = abi.decode(pairResult, (address));
            if (pair == address(0)) revert GetPoolData__InvalidPool();

            // Call the pool with the payload.
            (bool success, bytes memory callResult) = pair.staticcall(leg.poolRequestCalldata);
            if (!success) revert GetPoolData__ResultCallFailure();

            // Also return the order of the pair tokens.
            address token0 = IPair(pair).token0();
            tokens0[i] = token0;

            // We're not going to decode the result, because we don't know what is requested.
            results[i] = callResult;
        }
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
