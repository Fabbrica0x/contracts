// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";

contract EventFactory is ERC721URIStorage, EIP712 {
    string private constant SIGNING_DOMAIN = "Event-Domain";
    string private constant SIGNATURE_VERSION = "1";
    string private _baseURIString;
    string private _metadataTable;
    uint256 private _metadataTableId;
    string private _tablePrefix;
    string private _externalURL;

    constructor(
        string memory baseURI,
        string memory externalURL
    ) ERC721("EventNFT", "ENFT") EIP712("Event-NFT", "1") {
        _tablePrefix = "event";
        _baseURIString = baseURI;
        _externalURL = externalURL;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _eventIds;
    using ECDSA for bytes32;
    struct EventVoucher {
        uint256 eventId; //unique for every voucher
        address creator;
        uint256 minPrice;
    }
    struct EventNFT {
        uint256 eventId;
        address creator;
        uint256 minPrice;
        address buyer;
    }
    mapping(uint => EventNFT) public idToEventNFT; // stores nfts after they are minted to a buyer
    mapping(uint => EventVoucher) public idToEventNFTVoucher; // stores unminted nft vouchers , as it get minted it get removed from this.
    mapping(uint => bytes) public idToSignature;
    event createdEventVoucher(
        uint indexed eventId,
        address indexed creator,
        uint minPrice
    );
    event createdEventNFT(
        uint indexed eventId,
        address indexed creator,
        address indexed buyer,
        uint minPrice
    );

    /*
     * `createMetadataTable` initializes the token tables.
     */
    function createMetadataTable()
        external
        payable
        returns (
            // onlyOwner
            uint256
        )
    {
        // Create token metadata tables
        _metadataTableId = TablelandDeployments.get().create(
            address(this),
            /*
             *  CREATE TABLE prefix_chainId (
             *    int id,
             *    int x,
             *    int y
             *  );
             */
            SQLHelpers.toCreateFromSchema(
                "eventId int, uri string",
                _tablePrefix
            )
        );

        _metadataTable = SQLHelpers.toNameFromId(
            _tablePrefix,
            _metadataTableId
        );

        return _metadataTableId;
    }

    /*
     * `tokenURI` is an example of how to turn a row in your table back into
     * erc721 compliant metadata JSON. here, we do a simple SELECT statement
     * with function that converts the result into json.
     */
    function tokenURI(
        uint256 eventId
    ) public view virtual override returns (string memory) {
        require(
            _exists(eventId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory base = _baseURI();

        // Give token viewers a way to get at our table metadata
        /**
            SELECT
                json_object(
                    'name', 'Token #' || id,
                    'external_url', '<externalURL>',
                    'attributes',
                    json_array(
                    json_object(
                        'display_type', 'number',
                        'trait_type', 'x',
                        'value', x
                    ),
                    json_object(
                        'display_type', 'number',
                        'trait_type', 'y',
                        'value', y
                    )
                    )
                )
            FROM
            <prefix_chainId_tableId>
            WHERE
            id = <tokenId>
         */
        return
            string.concat(
                base,
                "query?unwrap=true&extract=true&statement=", // Set up an unwrap + extract for a single token
                "SELECT%20json_object%28%27name%27%2C%20%27Token%20%23%27%20%7C%7C%20id%2C%20%27external_url%27%2C%20",
                SQLHelpers.quote(_externalURL),
                "%2C%20%27attributes%27%2Cjson_array%28json_object%28%27display_type%27%2C%20%27number%27%2C%20%27trait_type%27%2C%20%27x%27%2C%20%27value%27%2C%20x%29%2Cjson_object%28%27display_type%27%2C%20%27number%27%2C%20%27trait_type%27%2C%20%27y%27%2C%20%27value%27%2C%20y%29%29%29%20FROM%20",
                _metadataTable,
                "%20WHERE%20id=",
                Strings.toString(eventId)
            );
    }

    function metadataURI() public view returns (string memory) {
        string memory base = _baseURI();
        return
            string.concat(
                base,
                "query?statement=", // Simple read query setup
                "SELECT%20*%20FROM%20",
                _metadataTable
            );
    }

    /*
     * `setExternalURL` provides an example of how to update a field for every
     * row in an table.
     */
    function setExternalURL(
        string calldata externalURL
    ) external /*onlyOwner */ {
        _externalURL = externalURL;
    }

    function modifyTokenURI(string memory _tokenURI, uint _eventId) public {
        // Update the row in tableland
        string memory setters = string.concat("uri=", _tokenURI);
        // Only update the row with the matching `id`
        string memory filters = string.concat(
            "eventId=",
            Strings.toString(_eventId)
        );
        // Update the table
        TablelandDeployments.get().mutate(
            address(this),
            _metadataTableId,
            SQLHelpers.toUpdate(
                _tablePrefix,
                _metadataTableId,
                setters,
                filters
            )
        );
    }

    function createNFTVoucher(
        uint _minPrice
    ) internal returns (EventVoucher memory) {
        _eventIds.increment();
        uint newEventId = _eventIds.current();
        // Tablland row initialization for a voucher with a specific eventId
        TablelandDeployments.get().mutate(
            address(this),
            _metadataTableId,
            SQLHelpers.toInsert(
                _tablePrefix,
                _metadataTableId,
                "eventId,uri",
                string.concat(Strings.toString(newEventId), ",uploading_uri")
            )
        );
        idToEventNFTVoucher[newEventId] = EventVoucher(
            newEventId,
            msg.sender,
            _minPrice
        );
        emit createdEventVoucher(newEventId, msg.sender, _minPrice);
        return idToEventNFTVoucher[newEventId];
    }

    function setSignature(bytes memory _sig, uint _eventId) public {
        idToSignature[_eventId] = _sig;
    }

    function redeem(
        address redeemer,
        EventVoucher calldata voucher
    ) public payable {
        bytes memory signature = idToSignature[voucher.eventId];
        address signer = _verify(voucher, signature);
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

        require(voucher.creator == signer, "Unauthorized minter");
        _mint(signer, voucher.eventId);
        // _setTokenURI(voucher.eventId, voucher.uri);
        _transfer(signer, redeemer, voucher.eventId);
        // updation of global variables
        // idToSignature[voucher.eventId] = 0;
        // idToEventNFTVoucher[voucher.eventId] = 0;
        idToEventNFT[voucher.eventId] = EventNFT(
            voucher.eventId,
            voucher.creator,
            voucher.minPrice,
            //   voucher.uri, // This uri need to be fetched from tableland
            redeemer
        );
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
                            "Event(uint256 eventId,address creator,uint256 minPrice)"
                        ),
                        voucher.eventId,
                        voucher.creator,
                        voucher.minPrice
                    )
                )
            );
    }
}
