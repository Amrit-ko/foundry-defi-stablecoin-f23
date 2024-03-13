//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    HelperConfig public helperConfig;
    // NetworkConfig public config;

    function setUp() public {
        helperConfig = new HelperConfig();
    }

    function testActiveNetworkConfig() public {
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();
        assert(wethUsdPriceFeed != address(0));
        assert(wbtcUsdPriceFeed != address(0));
        assert(weth != address(0));
        assert(wbtc != address(0));
        assert(deployerKey != 0);
    }

    function testGetSepoliaEthConfig() public {
        HelperConfig.NetworkConfig memory config = helperConfig.getSepoliaEthConfig();
        assertEq(config.wethUsdPriceFeed, 0x694AA1769357215DE4FAC081bf1f309aDC325306);
        assertEq(config.wbtcUsdPriceFeed, 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);
        assertEq(config.weth, 0xdd13E55209Fd76AfE204dBda4007C227904f0a81);
        assertEq(config.wbtc, 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
        assertEq(config.deployerKey, vm.envUint("PRIVATE_KEY"));
    }

    function testGetOrCreateAnvilConfig() public {
        HelperConfig.NetworkConfig memory config = helperConfig.getSepoliaEthConfig();
        assert(config.wethUsdPriceFeed != address(0));
        assert(config.wbtcUsdPriceFeed != address(0));
        assert(config.weth != address(0));
        assert(config.wbtc != address(0));
        assert(config.deployerKey != 0);
    }

    function testGetDecimals() public {
        assertEq(helperConfig.DECIMALS(), 8);
    }

    function getEthUsdPrice() public {
        assertEq(helperConfig.ETH_USD_PRICE(), 2000e8);
    }

    function getBtcUsdPrice() public {
        assertEq(helperConfig.BTC_USD_PRICE(), 1000e8);
    }

    function getDefaultAnvilKey() public {
        assertEq(helperConfig.DEFAULT_ANVIL_KEY(), 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
    }
}
