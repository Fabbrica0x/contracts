// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
pragma solidity ^0.8.0;

contract EventFactory is ERC721URIStorage, EIP712 {
    string private constant SIGNING_DOMAIN = "Event-Domain";
    string private constant SIGNATURE_VERSION = "1";

    constructor() ERC721("EventNFT", "ENT") EIP712("Event-NFT", "1") {}

    using Counters for Counters.Counter;
    Counters.Counter private _eventIds;
    using ECDSA for bytes32;
    struct EventVoucher {
        uint256 eventId;
        address creator;
        uint256 minPrice;
        string uri;
        bytes signature;
    }
    mapping(uint => EventVoucher) idToEvent;
    event createdEvent(
        uint indexed eventId,
        address indexed creator,
        uint minPrice
    );

    function redeem(
        address redeemer,
        EventVoucher calldata voucher,
        bytes memory signature
    ) public payable {
        address signer = _verify(voucher, signature);
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");
        _mint(signer, voucher.eventId);
        _setTokenURI(voucher.eventId, voucher.uri);
        _transfer(signer, redeemer, voucher.eventId);
    }

    function _verify(
        EventVoucher calldata voucher,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return digest.toEthSignedMessageHash().recover(signature);
    }

    function _hash(
        EventVoucher calldata voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Event(uint256 eventId,address creator,uint256 minPrice,string uri)"
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
