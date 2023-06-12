// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
pragma solidity ^0.8.0;

contract EventFactory is ERC721URIStorage, EIP712 {
    constructor(
        address payable minter
    ) ERC721("EventNFT", "ENT") EIP712("Event-NFT", "1") {}

    using Counters for Counters.Counter;
    Counters.Counter private _eventIds;
    using ECDSA for bytes32;
    struct Event {
        uint256 eventId;
        address creator;
        uint256 minPrice;
        string uri;
    }
    mapping(uint => Event) idToEvent;
    event createdEvent(
        uint indexed eventId,
        address indexed creator,
        uint minPrice
    );
    Event newEvent;

    function createEvent(string memory _tokenURI, uint _minPrice) internal {
        _eventIds.increment();
        //    newEvent.eventId = _eventIds.current();
        //     newEvent.minPrice = _minPrice;
        //     newEvent.creator = msg.sender;
        //     newEvent.uri=_tokenURI;
        //     emit createdEvent (
        //         newEvent.eventId,
        //         msg.sender,
        //         newEvent.minPrice

        //     );
        //     idToEvent[newEvent.eventId] = Event(
        //         newEvent.eventId,
        //         msg.sender,
        //         newEvent.minPrice,
        //         newEvent.uri

        //     );
    }

    function redeem(
        address redeemer,
        Event calldata voucher,
        bytes memory signature
    ) public payable returns (uint256) {
        address signer = _verify(voucher, signature);
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");
        _mint(signer, voucher.eventId);
        _setTokenURI(voucher.eventId, voucher.uri);
    }

    function _verify(
        Event calldata voucher,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return digest.toEthSignedMessageHash().recover(signature);
    }

    function _hash(Event calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Event(uint256 eventId, address creator,uint256 minPrice,string uri)"
                        ),
                        voucher.eventId,
                        voucher.creator,
                        voucher.minPrice,
                        keccak256(bytes(voucher.uri))
                    )
                )
            );
    }
}
