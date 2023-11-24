// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IPair} from "./interfaces/IPair.sol";
import {ISpectrumRouter, PoolRequestResult, PoolRequest, AmountsOut} from "./interfaces/ISpectrumRouter.sol";

contract SpectrumRouter is ISpectrumRouter, Ownable2StepUpgradeable {
    function initialize(address owner) public initializer {
        if (owner == address(0)) revert Initialize__InvalidOwner();
        __Ownable2Step_init();
        _transferOwnership(owner);
    }

    function getAmountsOutMulti(AmountsOut[][] calldata paths) external view returns (uint256[] memory amountOut) {
        uint256 length = paths.length;

        amountOut = new uint256[](length);
        for (uint256 i; i < length; i++) {
            uint256 result = getAmountsOut(paths[i]);
            amountOut[i] = result;
        }
    }

    function getAmountsOut(AmountsOut[] calldata path) public view returns (uint256 amountOut) {
        uint256 length = path.length;

        for (uint256 i; i < length; i++) {
            AmountsOut memory leg = path[i];

            // Instantly return 0 if the amountIn is 0.
            if (i == 0) {
                uint256 amountIn = _extractAmountIn(leg.data);
                if (amountIn == 0) return 0;
            }

            // Each payload consists of the amountIn + the path, thus
            // we need to replace the amountIn with the previous result.
            bytes memory data = i == 0 ? leg.data : _replaceAmountIn(leg.data, amountOut);

            // Call the router with the payload.
            (bool success, bytes memory callResult) = leg.router.staticcall(data);

            // If the call failed, return 0. Subsequent calls will also fail. This most likely
            // won't happen because amountIn is already sanitized, but it's better to be safe.
            if (!success) {
                return 0;
            }

            // Decode the result.
            uint256[] memory amounts = abi.decode(callResult, (uint256[]));
            if (amounts.length == 0) revert GetAmountsOut__ParseFailure();
            amountOut = amounts[amounts.length - 1];
        }
    }

    function getPoolRequestsMulti(PoolRequest[][] calldata paths) external view returns (PoolRequestResult[] memory result) {
        uint256 length = paths.length;

        result = new PoolRequestResult[](length);
        for (uint256 i; i < length; i++) {
            (bytes[] memory results, address[] memory tokens0) = getPoolRequests(paths[i]);
            result[i] = PoolRequestResult({results: results, tokens0: tokens0});
        }
    }

    function getPoolRequests(PoolRequest[] calldata path) public view returns (bytes[] memory results, address[] memory tokens0) {
        uint256 length = path.length;

        results = new bytes[](length);
        tokens0 = new address[](length);
        for (uint256 i; i < length; i++) {
            PoolRequest memory leg = path[i];

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

    function _replaceAmountIn(bytes memory data, uint256 amountIn) private pure returns (bytes memory) {
        // 0xd06ca61f
        // 0000000000000000000000000000000000000000000000000de0b6b3a7640000 -> 1 ether
        // 0000000000000000000000000000000000000000000000000000000000000040
        // 0000000000000000000000000000000000000000000000000000000000000002
        // 000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
        // 000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

        bytes memory result;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := data
            mstore(add(result, 36), amountIn)
        }
        return result;
    }

    function _extractAmountIn(bytes memory data) private pure returns (uint256 amountIn) {
        assembly {
            amountIn := mload(add(data, 36))
        }
    }
}
