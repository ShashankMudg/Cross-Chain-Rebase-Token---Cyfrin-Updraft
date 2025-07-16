// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Rebase_Token} from "../src/Rebase_Token.sol";
import {vault} from "../src/vault.sol";
import {IRebase_Token} from "../src/interfaces/IRebase_Token.sol";

contract RebaseTokenTest is Test {
    Rebase_Token public rebasetoken;
    vault public Vault;
    address public user = makeAddr("user");
    address public admin = makeAddr("admin");
    address public recepient = makeAddr("recepient");

    function setUp() public {
        vm.startPrank(admin);
        rebasetoken = new Rebase_Token();
        Vault = new vault(IRebase_Token(address(rebasetoken)));
        rebasetoken.grantMintandBurnRole(address(Vault));
        vm.stopPrank();
    }

    function rewardVault(uint amount) public {
        (bool success, ) = payable(address(Vault)).call{value: amount}("");
    }

    function testDepositLinear(uint256 amount) public {
        amount =bound(amount, 1e5, 100 ether);
        vm.startPrank(user);
        vm.deal(user, 100 ether);
        Vault.deposit{value: amount}();
        uint startBalance = rebasetoken.balanceOf(user);
        console.log("startBalance", startBalance);
        vm.warp(block.timestamp + 1 days);
        uint MiddleBalance = rebasetoken.balanceOf(user);
        console.log("MiddleBalance", MiddleBalance);
        assertGe(MiddleBalance, startBalance);
        vm.warp(block.timestamp + 1 days);
        uint endBalance = rebasetoken.balanceOf(user);
        console.log("endBalance", endBalance);
        assertGe(endBalance, MiddleBalance);
        assertApproxEqAbs(MiddleBalance - startBalance, endBalance - MiddleBalance, 1);
        vm.stopPrank();

    }

    function testWithdrawLinear(uint256 amount) public {
        amount =bound(amount, 1e5, 100 ether);
        vm.startPrank(user);
        vm.deal(user, 100 ether);
        Vault.deposit{value: amount}();
        uint startBalance = rebasetoken.balanceOf(user);
        console.log("startBalance", startBalance);
        Vault.withdraw(type(uint256).max);
        assertEq(rebasetoken.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }


    function testRedeemaftertimepassed(uint256 amount, uint256 time) public {
        amount =bound(amount, 1e5, 100 ether);
        time =bound(time, 1000, (type(uint64).max)-1);
        vm.deal(user, amount);
        vm.prank(user);
        Vault.deposit{value: amount}();
        vm.warp(block.timestamp + time);
        uint startBalance = rebasetoken.balanceOf(user);
        console.log("startBalance", startBalance);
        vm.prank(admin);
        rewardVault(amount-startBalance);
        vm.prank(user);
        Vault.withdraw(type(uint256).max);
        uint ethBalance = address(user).balance;
        assertApproxEqAbs(ethBalance, startBalance, 1e6);
        assertGe(ethBalance, amount);
    }

    function testTransferLinear(uint256 amount, uint amounttoSend) public {
        amount =bound(amount, 1e5, 100 ether);
        amounttoSend =bound(amounttoSend, 1e5 , amount);
        vm.startPrank(user);
        vm.deal(user, amount);
        Vault.deposit{value: amount}();
        //uint startBalance = rebasetoken.balanceOf(user);
        rebasetoken.transfer(recepient, amounttoSend);
        uint endBalance = rebasetoken.balanceOf(user);
        console.log("endBalance", endBalance);
        vm.stopPrank();
        uint recepientbalance = rebasetoken.balanceOf(recepient);
        console.log("recepientbalance", recepientbalance);
        assertEq(endBalance, amount-amounttoSend);
        assertEq(recepientbalance, amounttoSend);
        assertEq(rebasetoken.balanceOf(user), amount-amounttoSend);
    }

    function testCannotsetinterestrate() public {
        vm.startPrank(user);
        rebasetoken.setinterestrate(3*uint256(rebasetoken.Precesion_factor())/1e8);
        vm.stopPrank();
    }

    function testCannotcallmintandburn() public {
        vm.prank(address(Vault));
        uint interestRate = rebasetoken.getCurrentInterestRate();
        rebasetoken.mint(user, 1e2, interestRate);
    }


    //pass
    function testgrantrole() public {
        vm.prank(admin);
        rebasetoken.grantMintandBurnRole(user);
        assertEq(rebasetoken.hasRole(keccak256("MINT_AND_BURN_ROLE"), user), true);
    }

    function testgetPrincipalamount(uint amount) public {
        amount = bound(amount, 1e5, 100 ether);
        vm.startPrank(user);
        vm.deal(user, amount);
        Vault.deposit{value: amount}();
        vm.warp(block.timestamp + 1 days);
        uint principalamount = rebasetoken.principlabalance(user);
        console.log("principalamount", principalamount);
        assertEq(principalamount, amount);
        vm.stopPrank();
    } 



    //pass
    function testGetRabsetokenaddress() view public {
        address rebasetokenaddress = address(Vault.getRebaseAddress());
        assertEq(rebasetokenaddress, address(rebasetoken));
    }

    //pass
    function testInterestRateCannotIncrease() public {
    vm.startPrank(admin);

    //uint256 currentRate = rebasetoken.getCurrentInterestRate(); // Assume 5e19
    uint256 newRate = 8 * rebasetoken.Precesion_factor() / 1e8; // 8%

    // The revert will return the CURRENT rate (not the one passed in)
    vm.expectRevert(abi.encodeWithSelector(
        Rebase_Token.InvalidInterestRate.selector, newRate
    ));
    rebasetoken.setinterestrate(newRate); // trying to increase from 5% to 8%
    
    vm.stopPrank();
}


}