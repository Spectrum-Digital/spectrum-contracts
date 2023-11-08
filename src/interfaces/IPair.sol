// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPair {
    function token0() external view returns (address);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
