// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/FundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe;

    address USER = makeAddr("user");
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, 20 ether);
    }

    function testMinimumDollarIsFive() public view {
        console.log("hello!");
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public view {
        console.log("owner", fundMe.getOwner());
        console.log("msg.sender", msg.sender);
        console.log("THIS", address(this));

        console.log("DeployFundMe Address:", address(deployFundMe)); // New instance
        console.log("FundMe Owner Address:", fundMe.getOwner()); // Owner from contract
        console.log("Test Contract Address (this):", address(this)); // FundMeTest
        console.log("msg.sender:", msg.sender); // Foundry test runner
        // assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        console.log("version", version);
        assertEq(version, block.chainid == 1 ? 6 : 4);
    }

    function testConversionRate() public view {
        uint256 rate = fundMe.getCurrentConversionRate();
        console.log("rate", rate);
        uint256 t = 6;
        assertEq(t, 6);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // Next line should revert!
        fundMe.fund{value: 0.001 ether}();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next TX will be sent by USER
        console.log("USER", USER);
        fundMe.fund{value: 3e18}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        console.log("User Balance", USER.balance);
        assertEq(amountFunded, 3e18);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: 2e18}();

        address funder = fundMe.getFunder(0);

        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: 3e18}();
        _;
    }

    function testOnlyOnwerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank
            // vm.deal
            hoax(address(i), 2e18); // similar to prank and deal combined
            fundMe.fund{value: 2e18}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft();
        console.log("GAS START", gasStart);
        console.log("GAS PRICE", tx.gasprice);
        vm.txGasPrice(GAS_PRICE);
        console.log("NEW GAS PRICE", tx.gasprice);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        console.log("GAS END", gasEnd);
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("GAS USED", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank
            // vm.deal
            hoax(address(i), 2e18); // similar to prank and deal combined
            fundMe.fund{value: 2e18}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft();
        console.log("GAS START", gasStart);
        console.log("GAS PRICE", tx.gasprice);
        vm.txGasPrice(GAS_PRICE);
        console.log("NEW GAS PRICE", tx.gasprice);
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        uint256 gasEnd = gasleft();
        console.log("GAS END", gasEnd);
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("GAS USED", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
