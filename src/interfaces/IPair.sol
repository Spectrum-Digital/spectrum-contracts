// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IUniswapV2Pair is IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ISolidlyPair is IPair {
    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast);
}
