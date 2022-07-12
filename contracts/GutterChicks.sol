// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract GutterCatChicks is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    IERC20 public rewardsToken;

    // The IPFS URI for the metadata folder.
    // Format: "ipfs://your_uri/".
    string internal uri;

    // KingPins URI
    string internal kingpinsUri;

    // The format of your metadata files
    string internal constant uriSuffix = ".json";

    // The URI for Hidden Metadata
    string internal hiddenMetadataUri;

    // Price of one NFT
    uint256 public cost = 0.07 ether;

    // Price of one NFT for presale
    uint256 public presaleCost = 0.05 ether;

    // The maximum supply
    uint256 public constant maxSupply = 3000;

    // Amount of Chicks minted from team reserve
    uint256 public currentTeamSupply;

    // Amount of Chicks reserved for the team and giveaways
    uint256 public constant maxTeamSupply = 100;

    // The maximum mint amount allowed per transaction in Main Sale
    uint256 public maxMintAmountMainSale = 5;

    // The maximum mint amount allowed per transaction in Pre Sale
    uint256 public maxMintAmountPreSale = 3;

    // The paused state for minting
    bool public paused = true;

    // The revealed state for Tokens Metadata
    bool public revealed = false;

    // Presale state
    bool public presale = false;

    // Mapping of whitelisted addresses
    mapping(address => bool) public whitelistedAddresses;

    // Constructor function that sets name and symbol
    // of the collection, cost, max supply and the maximum
    // amount a user can mint per transaction
    constructor() ERC721("Gutter Cat Chicks", "GCX") {}

    // Returns the current supply of the collection
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    // Mint function
    function mint(uint256 _mintAmount) public payable {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountMainSale,
            "Invalid mint amount!"
        );
        require(
            supply.current() + _mintAmount <= maxSupply - maxTeamSupply,
            "Max supply exceeded!"
        );
        require(!paused, "The contract is paused!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        _mintLoop(msg.sender, _mintAmount);
    }

    // Pre-Sale mint function for owners of Gutter Gang collections
    function presaleMint(uint256 _mintAmount) external payable {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPreSale,
            "Invalid mint amount!"
        );
        require(presale, "Presale is not active!");
        require(
            supply.current() + _mintAmount <= maxSupply - maxTeamSupply,
            "Max supply exceeded!"
        );
        require(whitelistedAddresses[msg.sender], "You are not whitelisted!");
        require(msg.value >= presaleCost * _mintAmount, "Insufficient funds!");
        whitelistedAddresses[msg.sender] = false;
        _mintLoop(msg.sender, _mintAmount);
    }

    // Mint function for owner that allows for free minting for a specified address
    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        require(currentTeamSupply <= maxTeamSupply);
        currentTeamSupply++;
        _mintLoop(_receiver, _mintAmount);
    }

    // Returns the Token Id for Tokens owned by the specified address
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    // Get sale state function for front end
    function getSaleState() external view returns (uint256 _salestate) {
        if (presale) {
            return 1;
        } else if (!paused) {
            return 2;
        } else {
            return 0;
        }
    }

    // Returns the Token URI with Metadata for specified Token Id
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (!revealed) {
            if (_tokenId <= 30) {
                bytes(kingpinsUri).length > 0
                    ? string(
                        abi.encodePacked(
                            kingpinsUri,
                            _tokenId.toString(),
                            uriSuffix
                        )
                    )
                    : "";
            }
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    // Whitelist addresses
    function whitelistAddresses(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 i; i < _addresses.length; ++i) {
            whitelistedAddresses[_addresses[i]] = true;
        }
    }

    // Changes the Revealed State
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    // Set the mint cost of one NFT
    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    // Set the hidden metadata URI
    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    // Set the URI of your IPFS/hosting server for the metadata folder.
    // Used in the format: "ipfs://your_uri/".
    function setUri(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    // Change paused state for main minting
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    // Change state of minting for presale
    function setPresale(bool _bool) public onlyOwner {
        presale = _bool;
    }

    // Withdraw ETH after sale in GCX Team Wallet
    function withdraw() public onlyOwner {
        (bool es, ) = payable(0xBCeF6fA9c27bC850627Cd7fDB393cfF06d31b9F8).call{
            value: (address(this).balance / 10)
        }("");
        require(es);
        (bool os, ) = payable(0x11bCf63EB29Ba1511B8941C6Ff52C3F288dECAE5).call{
            value: address(this).balance
        }("");
        require(os);
    }

    // Helper function
    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    // Helper function
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    // Just because you never know
    receive() external payable {}
}
