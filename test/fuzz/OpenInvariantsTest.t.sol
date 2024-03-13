// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.19;

// import {Test} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
// import {DSCEngine} from "../../src/DSCEngine.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {DeployDSC} from "../../script/DeployDSC.s.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract OpenInvariantsTest is StdInvariant, Test {
//     DeployDSC public deployer;
//     DSCEngine public dsce;
//     DecentralizedStableCoin public dsc;
//     HelperConfig public config;
//     address weth;
//     address beth;

//     function setUp() external {
//         deployer = new DeployDSC();
//         (dsc, dsce, config) = deployer.run();
//         targetContract(address(dsce));
//         (,, weth, beth,) = config.activeNetworkConfig();
//     }

//     function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
//         uint256 totalBethDeposited = IERC20(beth).balanceOf(address(dsce));

//         uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
//         uint256 bethValue = dsce.getUsdValue(beth, totalBethDeposited);

//         assert(wethValue + bethValue >= totalSupply);
//     }
// }
