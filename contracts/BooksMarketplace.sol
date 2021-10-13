// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BooksNFT.sol";
import "./NalndaToken.sol";

contract BooksMarketplace {

    NalndaToken private _token;
    BooksNFT private _book;

    address private _author;

    constructor(NalndaToken token, BooksNFT book) {
        _token = token;
        _book = book;
        _author = _book.getAuthor();
    }

    event Purchase(address indexed buyer, address seller, uint256 ticketId);

    // Purchase book from the author directly
    function purchaseBook() public {
        address buyer = msg.sender;

        _token.transferFrom(buyer, _author, _book.getBookPrice());

        _book.transferBook(buyer);
    }

    // Purchase book from the secondary market hosted by the author
    function secondaryPurchase(uint256 bookId) public {
        address seller = _book.ownerOf(bookId);
        address buyer = msg.sender;
        uint256 sellingPrice = _book.getSellingPrice(bookId);
        uint256 commision = (sellingPrice * 10) / 100;

        _token.transferFrom(buyer, seller, sellingPrice - commision);
        _token.transferFrom(buyer, _author, commision);

        _book.secondaryTransferBooks(buyer, bookId);

        emit Purchase(buyer, seller, bookId);
    }
}
