// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct ReservesHop {
    address pair;
    bytes data;
}

struct AmountsOutHop {
    address router;
    bytes data;
}

interface ISpectrumRouter {
    error SpectrumRouter__InvalidOwner();
    error SpectrumRouter__GetReservesCallFailure();
    error SpectrumRouter__GetReservesParseFailure();
    error SpectrumRouter__GetAmountsOutCallFailure();
    error SpectrumRouter__GetAmountsOutParseFailure();

    function getReserves(address tokenIn, ReservesHop[] calldata hops) external view returns (address token, bytes[] memory results);

    function getAmountsOut(address tokenIn, AmountsOutHop[] calldata hops) external view returns (address token, uint256 amountOut);
}
