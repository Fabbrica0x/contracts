// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/Counters.sol";
pragma solidity ^0.8.0;

contract EventFactory {
    using Counters for Counters.Counter;
    Counters.Counter private _eventIds;
    struct Event {
        uint eventId;
        uint minPrice;
        address creator;
    }
    event createdEvent(uint indexed eventId, address indexed creator);
    Event newEvent;

    function createEvent(uint _minPrice) internal {
        _eventIds.increment();
        newEvent.eventId = _eventIds.current();
        newEvent.minPrice = _minPrice;
        newEvent.creator = msg.sender;
        emit createdEvent(newEvent.eventId, msg.sender);
    }

    function deleteEvent(uint _tokenId) internal {
        // updating
    }
}
