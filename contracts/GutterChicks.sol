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

    // The URI of your IPFS/hosting server for the metadata folder.
    // Used in the format: "ipfs://your_uri/".
    string internal uri;

    // The format of your metadata files
    string internal constant uriSuffix = ".json";

    // The URI for your Hidden Metadata
    string internal hiddenMetadataUri;

    // Price of one NFT
    uint256 public cost = 0.05 ether;

    // Price of one NFT for presale
    uint256 public presaleCost = 0.04 ether;

    // The maximum supply of your collection
    uint256 public constant maxSupply = 3000;

    // Amount of Chicks minted from team reserve
    uint256 public currentTeamSupply = 0;

    // Amount of Chicks reserved for the team and giveaways
    uint256 public constant maxTeamSupply = 50;

    // The maximum mint amount allowed per transaction
    uint256 public maxMintAmountPerTx = 5;

    // The paused state for minting
    bool public paused = true;

    // The revealed state for Tokens Metadata
    bool public revealed = false;

    // Presale state
    bool public presale = false;

    // Staking state
    bool public staking = false;

    // Staker info
    struct Staker {
        // Amount of ERC721 Tokens staked
        uint256 amountStaked;
        // Last time of details update for this User
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
    }

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;

    // Mapping of Token Id to staked state
    mapping(uint256 => bool) public stakedState;

    // Mapping of whitelisted addresses
    mapping(address => bool) public whitelistedAddresses;

    // Rewards per hour per token deposited in wei.
    // Rewards are cumulated once every hour.
    uint256 private rewardsPerHour;

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
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
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
    function presaleMint() external payable {
        require(presale, "Presale is not active!");
        require(supply.current() + 1 <= maxSupply, "Max supply exceeded!");
        require(whitelistedAddresses[msg.sender], "You are not whitelisted!");
        require(msg.value >= presaleCost, "Insufficient funds!");
        whitelistedAddresses[msg.sender] = false;
        _mintLoop(msg.sender, 1);
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

    function stake(uint256 _tokenId) external {
        require(staking, "Staking is not live.");
        require(stakedState[_tokenId] == false, "Token already staked!");
        require(
            ownerOf(_tokenId) == msg.sender,
            "Can't stake tokens you don't own!"
        );
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }
        stakedState[_tokenId] = true;
        stakers[msg.sender].amountStaked++;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    function unstake(uint256 _tokenId) external {
        require(stakedState[_tokenId] == true, "Token is not staked!");
        require(
            ownerOf(_tokenId) == msg.sender,
            "Can't unstake tokens you don't own!"
        );
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;
        stakers[msg.sender].amountStaked--;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        rewardsToken.transfer(msg.sender, rewards);
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

    function getSaleState() external view returns (uint256 _salestate) {
        if (presale) {
            return 1;
        } else if (!paused) {
            return 2;
        } else {
            return 0;
        }
    }

    function userStakeInfo(address _user)
        public
        view
        returns (uint256[] memory, uint256)
    {
        uint256[] memory _tokensStaked = new uint256[](
            stakers[_user].amountStaked
        );
        uint256 stakedTokenIndex = 0;
        uint256[] memory tokensOwned = walletOfOwner(_user);
        for (uint256 i; i < tokensOwned.length; i++) {
            if (stakedState[tokensOwned[i]] == true) {
                _tokensStaked[stakedTokenIndex] = tokensOwned[i];
                stakedTokenIndex++;
            }
        }
        return (_tokensStaked, availableRewards(_user));
    }

    function availableRewards(address _user) internal view returns (uint256) {
        require(stakers[_user].amountStaked > 0, "User has no tokens staked");
        uint256 _rewards = stakers[_user].unclaimedRewards +
            calculateRewards(_user);
        return _rewards;
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

        if (revealed == false) {
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

    // Set the maximum mint amount per transaction
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
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

    // Change paused state of minting for presale
    function setPresale(bool _bool) public onlyOwner {
        presale = _bool;
    }

    // Set the address of the ERC20 Token
    function setToken(IERC20 _token) external onlyOwner {
        rewardsToken = _token;
    }

    // Withdraw ETH after sale
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 _rewards)
    {
        return (((
            ((block.timestamp - stakers[_staker].timeOfLastUpdate) *
                stakers[msg.sender].amountStaked)
        ) * rewardsPerHour) / 3600);
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

    // Override to block token transfers when staked
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(stakedState[tokenId] == false, "Can't transfer staked tokens!");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Just because you never know
    receive() external payable {}
}
