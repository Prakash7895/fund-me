// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) > 1e18) {
            revert FundMe__NotOwner();
        }
        // require(msg.value.getConversionRate() > 1e18, "didn't send enough eth");
        // require(getConversionRate(msg.value) > 1e18, "didn't send enough eth");

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] =
            addressToAmountFunded[msg.sender] +
            msg.value;
    }

    modifier onlyOnwer() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        // require(msg.sender == i_owner, "Must be Owner!");
        _;
    }

    function withdraw() public onlyOnwer {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

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
}
