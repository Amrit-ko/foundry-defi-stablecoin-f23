//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoin public dsc;
    address public USER = makeAddr("user");

    function setUp() public {
        dsc = new DecentralizedStableCoin();
    }
    /// Mint function ///

    function testMintsDscToUser() public {
        dsc.mint(USER, 100);
        assertEq(dsc.balanceOf(USER), 100);
    }

    function testMintRevertsOnZeroAddress() public {
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__NotZeroAddress.selector);
        dsc.mint(address(0), 100);
    }

    function testMintRevertsOnZeroAmount() public {
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.mint(USER, 0);
    }

    /// Burn function ///

    function testBurnsDscFromUser() public {
        dsc.mint(USER, 100);
        assertEq(dsc.balanceOf(USER), 100);
        dsc.transferOwnership(address(USER));
        vm.prank(USER);
        dsc.burn(100);
        assertEq(dsc.balanceOf(USER), 0);
    }

    function testBurnRevertsOnZeroAmount() public {
        dsc.mint(USER, 100);
        assertEq(dsc.balanceOf(USER), 100);
        dsc.transferOwnership(address(USER));
        vm.prank(USER);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.burn(0);
    }

    function testBurnRevertsIfNotOwner() public {
        dsc.mint(USER, 100);
        vm.prank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        dsc.burn(100);
    }

    function testBurnRevertsIfNotEnoughBalance() public {
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__BurnAmountExceedsBalance.selector);
        dsc.burn(108);
    }
}
