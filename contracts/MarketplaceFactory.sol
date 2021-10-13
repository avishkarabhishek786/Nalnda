// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BooksNFT.sol";
import "./BooksMarketplace.sol";

contract MarketplaceFactory is Ownable {

    struct BookDetails {
        string bookName;
        string bookSymbol;
        uint256 bookPrice;
        uint256 totalSupply;
        address marketplace;
    }

    address[] private activeSale;
    mapping(address => BookDetails) private activeSaleMapping;

    event Created(address ntfAddress, address marketplaceAddress);

    // Creates new NFT and a marketplace for its purchase
    function LaunchNewBook(
        NalndaToken token,
        string memory bookName,
        string memory bookSymbol,
        uint256 bookPrice,
        uint256 totalSupply
    ) public onlyOwner returns (address) {
        BooksNFT newBook =
            new BooksNFT(
                bookName,
                bookSymbol,
                bookPrice,
                msg.sender
            );

        BooksMarketplace newMarketplace =
            new BooksMarketplace(token, newBook);

        address newBookAddress = address(newBook);

        activeSale.push(newBookAddress);
        activeSaleMapping[newBookAddress] = BookDetails({
            bookName: bookName,
            bookSymbol: bookSymbol,
            bookPrice: bookPrice,
            totalSupply: totalSupply,
            marketplace: address(newMarketplace)
        });

        emit Created(newBookAddress, address(newMarketplace));

        return newBookAddress;
    }

    // Get all active books
    function getActiveBookSales() public view returns (address[] memory) {
        return activeSale;
    }

    // Get book's details
    function getBookDetails(address bookAddress)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            address
        )
    {
        return (
            activeSaleMapping[bookAddress].bookName,
            activeSaleMapping[bookAddress].bookSymbol,
            activeSaleMapping[bookAddress].bookPrice,
            activeSaleMapping[bookAddress].totalSupply,
            activeSaleMapping[bookAddress].marketplace
        );
    }
}
