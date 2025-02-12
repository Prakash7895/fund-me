// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__NotOwner();
        }
        // require(msg.value.getConversionRate() > 1e18, "didn't send enough eth");
        // require(getConversionRate(msg.value) > 1e18, "didn't send enough eth");

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] =
            s_addressToAmountFunded[msg.sender] +
            msg.value;
    }

    modifier onlyOnwer() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        // require(msg.sender == i_owner, "Must be Owner!");
        _;
    }

    function cheaperWithdraw() public onlyOnwer {
        uint256 fundersLength = s_funders.length;
        for (uint256 i = 0; i < fundersLength; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        // call
        (bool callSuccess /* bytes memory dataReturned */, ) = payable(
            msg.sender
        ).call{value: address(this).balance}("");
        if (!callSuccess) {
            revert FundMe__NotOwner();
        }
        // require(callSuccess, "Call Failed");
    }

    function withdraw() public onlyOnwer {
        for (uint256 i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        // transfer
        // msg.sender ==> type is address
        // payable (msg.sender) ==> type is payable
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess /* bytes memory dataReturned */, ) = payable(
            msg.sender
        ).call{value: address(this).balance}("");
        if (!callSuccess) {
            revert FundMe__NotOwner();
        }
        // require(callSuccess, "Call Failed");
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getCurrentConversionRate() public view returns (uint256) {
        (, int256 price, , , ) = s_priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    // Special functions
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // View / Pure functions (Getters)

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 idx) external view returns (address) {
        return s_funders[idx];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
