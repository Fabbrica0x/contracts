// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiveBidding {
    uint internal totalBidAmount = 0;
    uint internal maxBidAmt = 0;
    uint internal id = 0;
    mapping(uint => uint) amtToid;
    mapping(uint => address) idToadd;

    function LiveBidding() public payable {
        amtToid[msg.value] = id;
        idToadd[id] = msg.sender;
        id++;
        totalBidAmount = msg.value + totalBidAmount;
        if (msg.value > maxBidAmt) {
            maxBidAmt = msg.value;
        }
    }

    function getHighestBidder() public view returns (address) {
        uint maxAmt = maxBidAmt;
        uint idOfRecipient = amtToid[maxAmt];
        address recipient = idToadd[idOfRecipient];
        return recipient;
    }

    // only authorized entity
    function transferBidAmount(address recipient) public {
        payable(recipient).transfer(totalBidAmount);
    }
}
