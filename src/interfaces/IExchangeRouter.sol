// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IBasicRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}

interface IStructsRouter {
    struct Route {
        address from;
        address to;
        bool stable;
    }

    function getAmountsOut(uint256 amountIn, Route[] memory routes) external view returns (uint256[] memory amounts);
}

interface IStructsWithFactoryRouter {
    struct Route {
        address from;
        address to;
        bool stable;
        address factory;
    }

    function getAmountsOut(uint256 amountIn, Route[] memory routes) external view returns (uint256[] memory amounts);
}
