// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct AmountsOutHop {
    address router;
    bytes data;
}

struct PoolRequestLeg {
    address router;
    address factory;
    bytes getPairCalldata;
    bytes poolRequestCalldata;
}

struct PoolRequestCandidateResult {
    bytes[] results;
    address[] tokens0;
}

interface ISpectrumRouter {
    error Initialize__InvalidOwner();
    error GetPoolData__FactoryCallFailure();
    error GetPoolData__InvalidFactory();
    error GetPoolData__PairCallFailure();
    error GetPoolData__InvalidPool();
    error GetPoolData__ResultCallFailure();
    error GetAmountsOut__CallFailure();
    error GetAmountsOut__ParseFailure();

    function initialize(address owner) external;

    function getAmountsOutCandidates(AmountsOutHop[][] calldata candidates) external view returns (uint256[] memory amountOut);

    function getAmountsOut(AmountsOutHop[] calldata hops) external view returns (uint256 amountOut);

    function getPoolRequestsCandidates(
        PoolRequestLeg[][] calldata candidates
    ) external view returns (PoolRequestCandidateResult[] memory result);

    function getPoolRequests(PoolRequestLeg[] calldata legs) external view returns (bytes[] memory results, address[] memory tokens0);
}
