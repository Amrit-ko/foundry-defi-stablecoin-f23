// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC public deployer;
    DSCEngine public dsce;
    DecentralizedStableCoin public dsc;
    HelperConfig public config;
    address weth;
    address beth;
    Handler public handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        handler = new Handler(dsce, dsc);
        targetContract(address(handler));
        (,, weth, beth,) = config.activeNetworkConfig();
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalBethDeposited = IERC20(beth).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 bethValue = dsce.getUsdValue(beth, totalBethDeposited);
        console.log("wethValue", wethValue);
        console.log("bethValue", bethValue);
        console.log("totalSupply", totalSupply);
        console.log("totalMintCalled", handler.totalMintCalled());
        assert(wethValue + bethValue >= totalSupply);
    }

    function invariant_gettersShouldNotRevert() public view {
        dsce.getAdditionalFeedPrecision();
        dsce.getCollateralTokens();
        dsce.getDsc();
        dsce.getLiquidationBonus();
        dsce.getLiquidationPrecision();
        dsce.getLiquidationThreshold();
        dsce.getMinHealthFactor();
        dsce.getPrecision();
        dsce.getAccountInformation(address(this));
        dsce.getAccountCollateralValue(address(this));
        dsce.getCollateralDepositedInTokens(address(this), weth);
        dsce.getCollateralTokenPriceFeed(weth);
        dsce.getHealthFactor(address(this));
        dsce.getMintedDsc(address(this));
    }
}
