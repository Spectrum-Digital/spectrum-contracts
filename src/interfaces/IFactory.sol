// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function getPool(address tokenA, address tokenB, bool stable) external view returns (address pair);
}
