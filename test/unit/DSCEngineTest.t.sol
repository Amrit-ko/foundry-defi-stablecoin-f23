//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC public deployer;
    DSCEngine public engine;
    DecentralizedStableCoin public dsc;
    HelperConfig public config;
    address public ethUsdPriceFeed;
    address public weth;
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 amountCollateral = 10 ether;
    uint256 amountToMint = 100 ether;
    uint256 public collateralToCover = 20 ether;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(weth).mint(USER2, STARTING_ERC20_BALANCE * 2);
    }

    /// Constructor Tests ///

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses = [weth, weth];
        priceFeedAddresses = [ethUsdPriceFeed];
        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /// Price Tests ///

    function testGetUsdValue() external {
        uint256 ethAmount = 15e18;
        uint256 expectedValue = 30000e18;
        uint256 value = engine.getUsdValue(weth, ethAmount);
        assertEq(value, expectedValue);
    }

    function testGetTokenAmountFromUsd() external {
        uint256 usdAmount = 30000e18;
        uint256 expectedAmount = 15e18;
        uint256 amount = engine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(amount, expectedAmount);
    }

    /// depositCollateral Tests ///

    function testRevertsIfDepositCollateralZero() external {
        vm.prank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
        vm.prank(USER);
        engine.depositCollateral(weth, 0);
    }

    function testRevertsWithUnapprovedCollateral() public {
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        engine.depositCollateral(address(this), AMOUNT_COLLATERAL);
    }

    function testCollateralIsDeposited() external {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        uint256 currentCollateral = engine.getCollateralDepositedInTokens(address(USER), weth);
        assertEq(currentCollateral, AMOUNT_COLLATERAL);
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        uint256 collateralDeposited = engine.getCollateralDepositedInTokens(address(USER), weth);
        assertEq(collateralDeposited, AMOUNT_COLLATERAL);
        (uint256 dscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(address(USER));
        uint256 collateralValueInUsdExpected = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 dscMintedExpected = 0;
        assertEq(dscMinted, dscMintedExpected);
        assertEq(collateralValueInUsd, collateralValueInUsdExpected);
    }

    /// mintDsc Tests ///

    function testRevertsIfMintCollateralValueZero() public {
        vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
        engine.mintDsc(0);
    }

    function testMintsDscToUser() public depositedCollateral {
        uint256 collateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 dscToMint = collateralValueInUsd / 2;
        vm.prank(USER);
        engine.mintDsc(dscToMint);
        uint256 dscMinted = engine.getMintedDsc(address(USER));
        uint256 dscBalance = dsc.balanceOf(address(USER));
        assertEq(dscMinted, dscToMint);
        assertEq(dscBalance, dscToMint);
    }

    function testRevertsIfHealthFactorIsBroken() public depositedCollateral {
        uint256 collateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 dscToMint = collateralValueInUsd;
        uint256 userHealthFactor = (((collateralValueInUsd * 50) / 100) * 1e18) / dscToMint;
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, userHealthFactor));
        engine.mintDsc(dscToMint);
        vm.stopPrank();
    }

    /// BurnDsc function ///

    function testRevertsIfBurnAmountZero() public {
        vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
        engine.burnDsc(0);
    }

    function testBurnsDscFromUser() public depositedCollateral {
        uint256 collateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 dscToMint = collateralValueInUsd / 2;
        uint256 dscToBurn = dscToMint / 2;
        uint256 dscAfterBurning = dscToMint - dscToBurn;
        vm.startPrank(USER);
        engine.mintDsc(dscToMint);
        dsc.approve(address(engine), dscToBurn);
        engine.burnDsc(dscToBurn);
        vm.stopPrank();
        assertEq(engine.getMintedDsc(address(USER)), dscAfterBurning);
    }

    function testBurnsDscFromEngine() public depositedCollateral {
        uint256 collateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 dscToMint = collateralValueInUsd / 2;
        uint256 dscToBurn = dscToMint / 2;
        uint256 contractBalanceBefore = dsc.balanceOf(address(engine));
        vm.startPrank(USER);
        engine.mintDsc(dscToMint);
        dsc.approve(address(engine), dscToBurn);
        engine.burnDsc(dscToBurn);
        vm.stopPrank();
        assertEq(dsc.balanceOf(address(engine)), contractBalanceBefore);
    }

    function testRevertsIfTryingToBurnDscWithNoDscOnBalance() public depositedCollateral {
        uint256 collateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 dscToMint = collateralValueInUsd / 2;
        uint256 dscToBurn = dscToMint;
        vm.startPrank(USER);
        engine.mintDsc(dscToMint);
        dsc.approve(address(engine), dscToBurn);
        dsc.transfer(address(engine), dscToBurn);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        engine.burnDsc(dscToBurn);
        vm.stopPrank();
    }

    /// RedeemCollateral Function ///

    function testRevertsIfRedeemAmountZero() public {
        vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
        engine.redeemCollateral(weth, 0);
    }

    function testRedeemsCollatoralToUserAndUpdatesBalance() public depositedCollateral {
        uint256 userCollateralBalanceBefore = engine.getCollateralDepositedInTokens(address(USER), weth);
        uint256 userCollateralTokenBalancebefore = ERC20Mock(weth).balanceOf(address(USER));
        uint256 amountToRedeem = userCollateralBalanceBefore / 2;
        vm.prank(USER);
        engine.redeemCollateral(weth, amountToRedeem);
        assertEq(
            engine.getCollateralDepositedInTokens(address(USER), weth), userCollateralBalanceBefore - amountToRedeem
        );
        assertEq(ERC20Mock(weth).balanceOf(address(USER)), userCollateralTokenBalancebefore + amountToRedeem);
    }

    function testRedeemRevertsIfHealthFactorIsBroken() public depositedCollateral {
        uint256 collateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 dscToMint = collateralValueInUsd / 2;
        uint256 collateralValueInUsdToRedeem = engine.getUsdValue(weth, AMOUNT_COLLATERAL / 2);
        uint256 userHealthFactor = (((collateralValueInUsdToRedeem * 50) / 100) * 1e18) / dscToMint;
        vm.startPrank(USER);
        engine.mintDsc(dscToMint);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, userHealthFactor));
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL / 2);
    }

    /// Liquidate Function ///
    modifier depositCollateralAndMintDsc() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), amountCollateral);
        engine.depositCollateral(weth, amountCollateral);
        engine.mintDsc(amountToMint);
        vm.stopPrank();
        _;
    }

    function testRevertsIfLiquidationAmountZero() public {
        vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
        engine.liquidate(weth, address(USER), 0);
    }

    function testRevertsIfHealthFactorIsOk() public depositCollateralAndMintDsc {
        uint256 dscToMint = 100 ether;
        vm.startPrank(USER2);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL * 2);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL * 2);
        engine.mintDsc(dscToMint);
        dsc.approve(address(engine), dscToMint);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        engine.liquidate(weth, address(USER), dscToMint);
    }

    function testLiquidatesUserIfHealthFActorIsBroken() public {
        MockV3Aggregator fakePriceFeed = new MockV3Aggregator(8, 2000e8);
        ERC20Mock feth = new ERC20Mock("Fake Ether", "FETH", msg.sender, 1000e8);
        tokenAddresses = [weth, address(feth)];
        priceFeedAddresses = [ethUsdPriceFeed, address(fakePriceFeed)];
        DecentralizedStableCoin dscFake = new DecentralizedStableCoin();
        DSCEngine engineWithFakePriceFeed = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dscFake));
        dscFake.transferOwnership(address(engineWithFakePriceFeed));
        ERC20Mock(feth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(weth).mint(USER2, STARTING_ERC20_BALANCE * 2);
        vm.startPrank(USER);
        ERC20Mock(feth).approve(address(engineWithFakePriceFeed), amountCollateral);
        engineWithFakePriceFeed.depositCollateral(address(feth), amountCollateral);
        engineWithFakePriceFeed.mintDsc(amountToMint);
        vm.stopPrank();
        fakePriceFeed.updateAnswer(20e8);
        vm.startPrank(USER2);
        ERC20Mock(weth).approve(address(engineWithFakePriceFeed), collateralToCover);
        engineWithFakePriceFeed.depositCollateral(weth, collateralToCover);
        engineWithFakePriceFeed.mintDsc(amountToMint);
        dscFake.approve(address(engineWithFakePriceFeed), amountToMint);
        engineWithFakePriceFeed.liquidate(address(feth), address(USER), amountToMint);
        vm.stopPrank();
    }
    /// depositCollateralAndMintDsc Tests ///

    function testDepositCollateralAndMintDscUserInformation() public {
        uint256 userCollateralBalanceBefore = engine.getCollateralDepositedInTokens(address(USER), weth);
        uint256 userCollateralTokenBalanceBefore = ERC20Mock(weth).balanceOf(address(USER));
        uint256 collateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 dscToMint = collateralValueInUsd / 2;
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, dscToMint);
        assertEq(
            engine.getCollateralDepositedInTokens(address(USER), weth), userCollateralBalanceBefore + AMOUNT_COLLATERAL
        );
        assertEq(ERC20Mock(weth).balanceOf(address(USER)), userCollateralTokenBalanceBefore - AMOUNT_COLLATERAL);
        assertEq(engine.getMintedDsc(address(USER)), dscToMint);
    }

    /// redeemCollateralForDsc Tests ///

    function testRedeemCollateralForDscRevertsOnZeroAmountCollateral() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
        engine.redeemCollateralForDsc(weth, 0, amountToMint);
        vm.stopPrank();
    }

    function testRedeemCollateralForDscRevertsWithNotAllowedToken() public {
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        engine.redeemCollateralForDsc(address(this), amountCollateral, amountToMint);
    }

    function testRedeemsCollateralAndBurnsDsc() public depositCollateralAndMintDsc {
        vm.startPrank(USER);
        uint256 userCollateralBalanceBefore = engine.getCollateralDepositedInTokens(address(USER), weth);
        uint256 userDscBalanceBefore = dsc.balanceOf(address(USER));
        dsc.approve(address(engine), amountToMint);
        engine.redeemCollateralForDsc(weth, amountCollateral, amountToMint);
        vm.stopPrank();
        assertEq(
            engine.getCollateralDepositedInTokens(address(USER), weth), userCollateralBalanceBefore - amountCollateral
        );
        assertEq(dsc.balanceOf(address(USER)), userDscBalanceBefore - amountToMint);
    }

    function testRedeemCollateralForDscRevertsIfHealthFActorIsBroken() public depositCollateralAndMintDsc {
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(20e8);
        vm.startPrank(USER);
        dsc.approve(address(engine), amountToMint);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, 0));
        engine.redeemCollateralForDsc(weth, amountCollateral, amountToMint - 1);
        vm.stopPrank();
    }

    /// calculateHealthFactor Tests ///

    function testCalculateHealthFactorGivesCorrectAnswer() public depositCollateralAndMintDsc {
        uint256 healthFactor = engine.calculateHealthFactor(amountToMint, engine.getUsdValue(weth, amountCollateral));
        assertEq(healthFactor, engine.getHealthFactor(address(USER)));
    }

    /// Getters tests ///

    function testGetAccountCollateralValue() public depositedCollateral {
        uint256 collateralValue = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 accountCollateralValue = engine.getAccountCollateralValue(address(USER));
        assertEq(collateralValue, accountCollateralValue);
    }

    function testGetCollateralDepositedInTokens() public depositedCollateral {
        uint256 collateralDeposited = engine.getCollateralDepositedInTokens(address(USER), weth);
        assertEq(collateralDeposited, AMOUNT_COLLATERAL);
    }

    function testGetMintedDsc() public depositCollateralAndMintDsc {
        uint256 dscMinted = engine.getMintedDsc(address(USER));
        assertEq(dscMinted, amountToMint);
    }

    function testGetAccountInformation() public depositCollateralAndMintDsc {
        (uint256 dscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(address(USER));
        assertEq(dscMinted, amountToMint);
        assertEq(collateralValueInUsd, engine.getUsdValue(weth, AMOUNT_COLLATERAL));
    }

    function testGetCollateralTokens() public {
        address[] memory collateralTokens = engine.getCollateralTokens();
        assertEq(collateralTokens[0], weth);
        assertEq(collateralTokens.length, 2);
    }
}
