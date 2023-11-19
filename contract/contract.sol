// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

// Importing console for debugging (mostly used in local testing).
import "hardhat/console.sol";
// Importing OpenZeppelin's Counters utility for secure counter management.
import "@openzeppelin/contracts/utils/Counters.sol";
// Importing OpenZeppelin's ERC721URIStorage and ERC721 for NFT functionality.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Main contract for the NFT Marketplace, inheriting ERC721URIStorage for NFT functionality.
contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    // Counter for tracking token IDs.
    Counters.Counter private _tokenIds;
    // Counter for tracking the number of items sold.
    Counters.Counter private _itemsSold;

    // Address of the contract owner (the one who deployed the contract).
    address payable owner;
    // Listing price to be paid for listing an NFT on the marketplace.
    uint256 listPrice = 0.01 ether;

    // Structure to store information about a token listed on the marketplace.
    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    // Event emitted when a token is successfully listed on the marketplace.
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );

    // Mapping from token ID to its corresponding listing information.
    mapping(uint256 => ListedToken) private idToListedToken;

    // Constructor to set up the NFT marketplace.
    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }

    // Allows the owner to update the listing price.
    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only marketplace owner can update the listing price.");
        listPrice = _listPrice;
    }

    // Function to get the current listing price.
    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    // Retrieve the latest token's listing information.
    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    // Get listing information for a specific token ID.
    function getListedTokenForId(uint256 tokenId) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }

    // Returns the current highest token ID.
    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    // Function to create a new token and list it on the marketplace.
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        // Increase the token ID for the new NFT.
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Minting the new NFT to the sender's address.
        _safeMint(msg.sender, newTokenId);

        // Assigning the provided URI to the newly minted token.
        _setTokenURI(newTokenId, tokenURI);

        // Internal function to add the token to the marketplace's listing.
        createListedToken(newTokenId, price);

        return newTokenId;
    }

    // Private helper function to handle listing of a newly created token.
    function createListedToken(uint256 tokenId, uint256 price) private {
        require(msg.value == listPrice, "Listing fee must be equal to the set list price.");
        require(price > 0, "Price must be positive.");

        // Updating our tokenId to Token details mapping.
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );

        // Transferring the token to the marketplace contract.
        _transfer(msg.sender, address(this), tokenId);

        // Emitting event for frontend integration and user notifications.
        emit TokenListedSuccess(
            tokenId,
            address(this),
            msg.sender,
            price,
            true
        );
    }
    
    // Retrieves all NFTs currently listed on the marketplace.
    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;
        uint currentId;

        for(uint i = 0; i < nftCount; i++) {
            currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return tokens;
    }
    
    // Retrieves all NFTs owned or sold by the caller.
    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        // Calculating the number of NFTs owned or sold by the caller.
        for(uint i = 0; i < totalItemCount; i++) {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        // Storing the relevant NFTs in an array.
        ListedToken[] memory items = new ListedToken[](itemCount);
        for(uint i = 0; i < totalItemCount; i++) {
            if(idToListedToken[i+1].owner == msg.sender || idToListedToken[i+1].seller == msg.sender) {
                uint currentId = i+1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Function to execute the sale of a token.
    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        require(msg.value == price, "Must submit the asking price to complete the purchase.");

        // Update the token's listing status and seller information.
        idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();

        // Transfer the token to the buyer.
        _transfer(address(this), msg.sender, tokenId);
        // Granting marketplace approval to manage the NFT.
        approve(address(this), tokenId);

        // Distributing the funds: listing fee to the owner, and sale proceeds to the seller.
        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }

    // Future implementation might include a function to allow users to resell tokens.
}
