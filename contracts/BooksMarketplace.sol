// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BooksNFT.sol";
import "./PurchaseToken.sol";

contract BooksMarketplace {

    PurchaseToken private _token;
    BooksNFT private _book;

    address private _organiser;

    constructor(PurchaseToken token, BooksNFT book) {
        _token = token;
        _book = book;
        _organiser = _book.getOrganiser();
    }

    event Purchase(address indexed buyer, address seller, uint256 ticketId);

    // Purchase tickets from the organiser directly
    function purchaseTicket() public {
        address buyer = msg.sender;

        _token.transferFrom(buyer, _organiser, _book.getBookPrice());

        _book.transferBook(buyer);
    }

    // Purchase ticket from the secondary market hosted by organiser
    function secondaryPurchase(uint256 ticketId) public {
        address seller = _book.ownerOf(ticketId);
        address buyer = msg.sender;
        uint256 sellingPrice = _book.getSellingPrice(ticketId);
        uint256 commision = (sellingPrice * 10) / 100;

        _token.transferFrom(buyer, seller, sellingPrice - commision);
        _token.transferFrom(buyer, _organiser, commision);

        _book.secondaryTransferBooks(buyer, ticketId);

        emit Purchase(buyer, seller, ticketId);
    }
}
