// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {SpectrumRouter} from "../src/SpectrumRouter.sol";
import {ISpectrumRouter, AmountsOutHop} from "../src/interfaces/ISpectrumRouter.sol";
import {IBasicRouter, IStructsRouter, IStructsWithFactoryRouter} from "../src/interfaces/IExchangeRouter.sol";

contract SpectrumRouterTest is Test {
    uint256 mainnetForkId;
    uint256 baseForkId;

    address public constant mainnet_wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant mainnet_weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant mainnet_usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant mainnet_uniswap_router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant mainnet_sushiswap_router = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    address public constant base_aero = 0x940181a94A35A4569E4529A3CDfB74e38FD98631;
    address public constant base_weth = 0x4200000000000000000000000000000000000006;
    address public constant base_usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant base_baseswap_router = 0x327Df1E6de05895d2ab08513aaDD9313Fe505d86;
    address public constant base_aerodrome_router = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    address public constant base_aerodrome_factory = 0x420DD381b31aEf6683db6B902084cB0FFECe40Da;

    address public owner;
    ISpectrumRouter public mainnet_router;
    ISpectrumRouter public base_router;

    function setUp() public {
        owner = msg.sender;

        // Creates a mainnet fork
        uint256 mainnetForkBlock = 18462000;
        mainnetForkId = vm.createSelectFork(vm.rpcUrl("mainnet"), mainnetForkBlock);

        // Creates a base fork
        uint256 baseForkBlock = 5937209;
        baseForkId = vm.createSelectFork(vm.rpcUrl("base"), baseForkBlock);

        // Deploy the router on mainnet
        vm.selectFork(mainnetForkId);
        mainnet_router = new SpectrumRouter();
        mainnet_router.initialize(owner);

        // Deploy the router on base
        vm.selectFork(baseForkId);
        base_router = new SpectrumRouter();
        base_router.initialize(owner);
    }

    function testGetAmountsOutSingleHop() public returns (uint256 amountOut) {
        vm.selectFork(mainnetForkId);

        // Easy access to the variables
        address token0 = mainnet_weth;
        address token1 = mainnet_usdc;
        address exchange_router = mainnet_uniswap_router;
        bytes4 selector = IBasicRouter.getAmountsOut.selector;

        // Construct our path
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        bytes memory data = abi.encodeWithSelector(selector, 1 ether, path);

        // Construct our hops
        AmountsOutHop[] memory hops = new AmountsOutHop[](1);
        hops[0] = AmountsOutHop(exchange_router, data);

        // Execute the call
        amountOut = mainnet_router.getAmountsOut(hops);
        assertGt(amountOut, 0);
    }

    function testGetAmountsOutMultipleHops() public returns (uint256 amountOut) {
        vm.selectFork(mainnetForkId);

        // Easy access to the variables
        address token0 = mainnet_wbtc;
        address token1 = mainnet_weth;
        address token2 = mainnet_usdc;
        address exchange_router1 = mainnet_uniswap_router;
        address exchange_router2 = mainnet_sushiswap_router;
        bytes4 selector = IBasicRouter.getAmountsOut.selector;

        // Construct our path between token0 and token1
        address[] memory path1 = new address[](2);
        path1[0] = token0;
        path1[1] = token1;
        bytes memory data1 = abi.encodeWithSelector(selector, 10 ** 8, path1);

        // Construct our path between token1 and token2
        address[] memory path2 = new address[](2);
        path2[0] = token1;
        path2[1] = token2;
        // Note: this 1 ether will be automatically overridden by the amountOut of the previous hop
        bytes memory data2 = abi.encodeWithSelector(selector, 1 ether, path2);

        // Construct our hops
        AmountsOutHop[] memory hops = new AmountsOutHop[](2);
        hops[0] = AmountsOutHop(exchange_router1, data1);
        hops[1] = AmountsOutHop(exchange_router2, data2);

        // Execute the call
        amountOut = mainnet_router.getAmountsOut(hops);
        assertGt(amountOut, 0);
    }

    function testGetAmountsOutMultipleRouterTypes() public returns (uint256 amountOut) {
        vm.selectFork(baseForkId);

        // Easy access to the variables
        address token0 = base_aero;
        address token1 = base_weth;
        address token2 = base_usdc;

        // Construct our path between token0 and token1 using the StructsWithFactoryRouter
        IStructsWithFactoryRouter.Route[] memory routes = new IStructsWithFactoryRouter.Route[](1);
        routes[0] = IStructsWithFactoryRouter.Route(token0, token1, false, base_aerodrome_factory);
        bytes memory data1 = abi.encodeWithSelector(IStructsWithFactoryRouter.getAmountsOut.selector, 1 ether, routes);

        // Construct our path between token1 and token2 using the BasicRouter
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        bytes memory data2 = abi.encodeWithSelector(IBasicRouter.getAmountsOut.selector, 1 ether, path);

        // Construct our hops
        AmountsOutHop[] memory hops = new AmountsOutHop[](2);
        hops[0] = AmountsOutHop(base_aerodrome_router, data1);
        hops[1] = AmountsOutHop(base_baseswap_router, data2);

        // Execute the call
        amountOut = base_router.getAmountsOut(hops);
        assertGt(amountOut, 0);
    }
}
