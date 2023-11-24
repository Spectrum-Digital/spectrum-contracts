// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct AmountsOut {
    address router;
    bytes data;
}

struct PoolRequest {
    address router;
    address factory;
    bytes getPairCalldata;
    bytes poolRequestCalldata;
}

struct PoolRequestResult {
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

    /**
     * @dev Initialize the contract.
     * @param owner The address of the owner of the contract.
     */
    function initialize(address owner) external;

    function getAmountsOutMulti(AmountsOut[][] calldata paths) external view returns (uint256[] memory amountOut);

    function getAmountsOut(AmountsOut[] calldata path) external view returns (uint256 amountOut);

    function getPoolRequestsMulti(PoolRequest[][] calldata paths) external view returns (PoolRequestResult[] memory result);

    function getPoolRequests(PoolRequest[] calldata path) external view returns (bytes[] memory results, address[] memory tokens0);
}
