// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiveTipping {
    uint internal totalBidAmount = 0;
    uint internal maxBidAmt = 0;
    uint internal id = 0;
    struct Bidder {
        uint id;
        uint totalTip;
        bool oldBidder;
    }
    mapping(address => Bidder) addToBidder;
    mapping(uint => address) idToadd;

    function LiveBidding() public payable {
        require(msg.value > 0, "Tip must be greater than zero");
        uint currentTip = addToBidder[msg.sender].totalTip;
        uint updateTip = currentTip + msg.value;
        addToBidder[msg.sender] = Bidder(id, updateTip, true);
        idToadd[id] = msg.sender;
        if (addToBidder[msg.sender].oldBidder == false) {
            id++;
        }
        totalBidAmount = msg.value + totalBidAmount;
    }

    function getHighestBidder() public returns (address) {
        uint currTip = 0;
        address recipient;
        for (uint i = 0; i <= id; i++) {
            address checkAdd = idToadd[i];
            currTip = addToBidder[checkAdd].totalTip;
            if (currTip > maxBidAmt) {
                maxBidAmt = currTip;
            }
        }
        for (uint i = 0; i <= id; i++) {
            address checkAdd = idToadd[i];
            if (addToBidder[checkAdd].totalTip == maxBidAmt) {
                recipient = checkAdd;
            }
        }
        return recipient;
    }

    // only authorized entity
    function transferBidAmount(address recipient) public {
        payable(recipient).transfer(totalBidAmount);
    }
}
