// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BooksNFT is Context, AccessControl, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _bookCopyIds;
    Counters.Counter private _bookSaleTicketId;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct BookSaleDetails {
        uint256 purchasePrice;
        uint256 sellingPrice;
        bool forSale;
    }

    address private _organiser;
    address[] private customers;
    uint256[] private bookCopyForSale;
    uint256 private _bookPrice;
    uint256 private _totalSupply;

    mapping(uint256 => BookSaleDetails) private _bookSaleDetails;
    mapping(address => uint256[]) private purchasedBookCopies;

    constructor(
        string memory bookName,
        string memory BookSymbol,
        uint256 bookPrice,
        uint256 totalSupply,
        address organiser
    ) ERC721(bookName, BookSymbol) {
        _setupRole(MINTER_ROLE, organiser);

        _bookPrice = bookPrice;
        _totalSupply = totalSupply;
        _organiser = organiser;
    }

    // Function to fix "Derived contract must override function" error
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier isValidBookCount {
        require(
            _bookCopyIds.current() < _totalSupply,
            "Maximum copies limit exceeded!"
        );
        _;
    }

    modifier isMinterRole {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "User must have minter role to mint"
        );
        _;
    }

    modifier isValidSellAmount(uint256 bookCopyId) {
        uint256 purchasePrice = _bookSaleDetails[bookCopyId].purchasePrice;
        uint256 sellingPrice = _bookSaleDetails[bookCopyId].sellingPrice;

        require(
            purchasePrice + ((purchasePrice * 110) / 100) > sellingPrice,
            "Re-selling price is more than 110%"
        );
        _;
    }

    /*
     * Mint new book and assign it to operator
     * Access controlled by minter only
     * Returns new bookCopyId
     */
    function mint(address operator)
        internal
        virtual
        isMinterRole
        returns (uint256)
    {
        _bookCopyIds.increment();
        uint256 newBookCopyId = _bookCopyIds.current();
        _mint(operator, newBookCopyId);

        _bookSaleDetails[newBookCopyId] = BookSaleDetails({
            purchasePrice: _bookPrice,
            sellingPrice: 0,
            forSale: false
        });

        return newBookCopyId;
    }

    /*
     * Bulk mint specified number of book copies to assign it to a operator
     * Modifier to check the copies count is less than total supply
     */
    function bulkMintBookCopies(uint256 numOfBookCopies, address operator)
        public
        virtual
        isValidBookCount
    {
        require(
            (bookCounts() + numOfBookCopies) <= 1000,
            "Number of book copies exceeds maximum copies count"
        );

        for (uint256 i = 0; i < numOfBookCopies; i++) {
            mint(operator);
        }
    }

    /*
     * Primary purchase for the books
     * Adds new customer if not exists
     * Adds buyer to books mapping
     * Update books details
     */
    function transferBook(address buyer) public {
        _bookSaleTicketId.increment();
        uint256 bookSaleTicketId = _bookSaleTicketId.current();

        require(
            msg.sender == ownerOf(bookSaleTicketId),
            "Only initial purchase allowed"
        );

        transferFrom(ownerOf(bookSaleTicketId), buyer, bookSaleTicketId);

        if (!isCustomerExist(buyer)) {
            customers.push(buyer);
        }
        purchasedBookCopies[buyer].push(bookSaleTicketId);
    }

    /*
     * Secondary purchase for the books
     * Modifier to validate that the selling price shouldn't exceed 110% of purchase price for peer to peer transfers
     * Adds new customer if not exists
     * Adds buyer to books mapping
     * Remove books from the seller and from sale
     * Update books details
     */
    function secondaryTransferBooks(address buyer, uint256 bookSaleTicketId)
        public
        isValidSellAmount(bookSaleTicketId)
    {
        address seller = ownerOf(bookSaleTicketId);
        uint256 sellingPrice = _bookSaleDetails[bookSaleTicketId].sellingPrice;

        transferFrom(seller, buyer, bookSaleTicketId);

        if (!isCustomerExist(buyer)) {
            customers.push(buyer);
        }

        purchasedBookCopies[buyer].push(bookSaleTicketId);

        removeBookFromCustomer(seller, bookSaleTicketId);
        removeBookFromSale(bookSaleTicketId);

        _bookSaleDetails[bookSaleTicketId] = BookSaleDetails({
            purchasePrice: sellingPrice,
            sellingPrice: 0,
            forSale: false
        });
    }

    /*
     * Add books for sale with its details
     * Validate that the selling price shouldn't exceed 110% of purchase price
     * Organiser can not use secondary market sale
     */
    function setSaleDetails(
        uint256 bookCopyId,
        uint256 sellingPrice,
        address operator
    ) public {
        uint256 purchasePrice = _bookSaleDetails[bookCopyId].purchasePrice;

        require(
            purchasePrice + ((purchasePrice * 110) / 100) > sellingPrice,
            "Re-selling price is more than 110%"
        );

        // Should not be an organiser
        require(
            !hasRole(MINTER_ROLE, _msgSender()),
            "Functionality only allowed for secondary market"
        );

        _bookSaleDetails[bookCopyId].sellingPrice = sellingPrice;
        _bookSaleDetails[bookCopyId].forSale = true;

        if (!isSaleBookAvailable(bookCopyId)) {
            bookCopyForSale.push(bookCopyId);
        }

        approve(operator, bookCopyId);
    }

    // Get book actual price
    function getBookPrice() public view returns (uint256) {
        return _bookPrice;
    }

    // Get organiser's address
    function getOrganiser() public view returns (address) {
        return _organiser;
    }

    // Get current book copy id
    function bookCounts() public view returns (uint256) {
        return _bookCopyIds.current();
    }

    // Get next sale bookSlaeTicketId
    function getNextbookSaleTicketId() public view returns (uint256) {
        return _bookSaleTicketId.current();
    }

    // Get selling price for the book
    function getSellingPrice(uint256 bookCopyId) public view returns (uint256) {
        return _bookSaleDetails[bookCopyId].sellingPrice;
    }

    // Get all books available for sale
    function getBookCopyForSale() public view returns (uint256[] memory) {
        return bookCopyForSale;
    }

    // Get book details
    function getBookSaleDetails(uint256 bookCopyId)
        public
        view
        returns (
            uint256 purchasePrice,
            uint256 sellingPrice,
            bool forSale
        )
    {
        return (
            _bookSaleDetails[bookCopyId].purchasePrice,
            _bookSaleDetails[bookCopyId].sellingPrice,
            _bookSaleDetails[bookCopyId].forSale
        );
    }

    // Get all books owned by a customer
    function getBooksOfCustomer(address customer)
        public
        view
        returns (uint256[] memory)
    {
        return purchasedBookCopies[customer];
    }

    // Utility function to check if customer exists to avoid redundancy
    function isCustomerExist(address buyer) internal view returns (bool) {
        for (uint256 i = 0; i < customers.length; i++) {
            if (customers[i] == buyer) {
                return true;
            }
        }
        return false;
    }

    // Utility function used to check if book is already for sale
    function isSaleBookAvailable(uint256 bookCopyId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < bookCopyForSale.length; i++) {
            if (bookCopyForSale[i] == bookCopyId) {
                return true;
            }
        }
        return false;
    }

    // Utility function to remove books owned by customer from customer to books mapping
    function removeBookFromCustomer(address customer, uint256 bookCopyId)
        internal
    {
        uint256 numOfCopies = purchasedBookCopies[customer].length;

        for (uint256 i = 0; i < numOfCopies; i++) {
            if (purchasedBookCopies[customer][i] == bookCopyId) {
                for (uint256 j = i + 1; j < numOfCopies; j++) {
                    purchasedBookCopies[customer][j - 1] = purchasedBookCopies[
                        customer
                    ][j];
                }
                purchasedBookCopies[customer].pop();
            }
        }
    }

    // Utility function to remove book from sale list
    function removeBookFromSale(uint256 bookCopyId) internal {
        uint256 numOfCopies = bookCopyForSale.length;

        for (uint256 i = 0; i < numOfCopies; i++) {
            if (bookCopyForSale[i] == bookCopyId) {
                for (uint256 j = i + 1; j < numOfCopies; j++) {
                    bookCopyForSale[j - 1] = bookCopyForSale[j];
                }
                bookCopyForSale.pop();
            }
        }
    }

}
