// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFT is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    uint256 public constant MaxSupply = 777; //max tokens supply
    uint256 public constant Price = 0.00777 ether; // price of the tokens
    uint256 public constant tokenPerTransaction = 7; // token per transaction
    uint256 public reservedTokensCounter; // reserved tokens counter
    uint256 public constant reservedTokens = 77; // tokens reserved by the owner
    string public BaseURI; // URL of the metadata
    string public NotRevealedURI; // URL of the revealed metadata
    bool public RevealStatus = false; // Reveal Status
    address public developerAddress =
        0x000000000000000000000000000000000000dEaD; // developer wallet Address
    mapping(address => uint256) public tokensPerWallet; //amount of tokens owned by the address

    enum ContractStatus {
        Before,
        Sale,
        After,
        Reveal
    }
    ContractStatus public contractStatus; // Contract Status value
    struct NFTInformation {
        string gender;
    }
    mapping(uint256 => NFTInformation) nftInfos; // mapping of NFTInformation (uint256 => NFTInformation)

    mapping(address => bool) whitelist; // mapping of whitelist user addresses (address => bool)

    constructor(string memory _baseURI, string memory _notRevealedUri)
        ERC721("My NFT", "MN")
    {
        transferOwnership(msg.sender);
        contractStatus = ContractStatus.Before;
        setBaseURI(_baseURI);
        setNotRevealedURI(_notRevealedUri);
    }

    /**
     * @dev add user address to the Whitelist
     * @param _addresses: arraylist of user addresses
     */
    function whitelistAddresses(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    /**
     * @dev check if user wallet address is in the Whitelist
     * @param _address: address of the user
     * @return bool: true if user wallet address is in the Whitelist
     */
    function verifyAddress(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    /**
     * @dev public mint tokens
     * @param _amount: the amount of token to mint
     */
    function Mint(uint256 _amount) public payable nonReentrant {
        require(contractStatus != ContractStatus.After, "NFT: SOLD_OUT");
        require(contractStatus == ContractStatus.Sale, "NFT: SALE_NOT_STARTED");
        require(
            verifyAddress(msg.sender),
            "NFT:YOU_ARE_NOT_ALLOWED_TO_BUY_TOKENS"
        );
        uint256 _price = Price * _amount;
        require(msg.value >= _price, "NFT: YOU_SEND_THE_WRONG_VALUE");
        require(_amount > 0, "NFT: YOU_NEED_TO_MINT_AT_LEAST_ONE_TOKEN");
        require(
            tokensPerWallet[msg.sender] + _amount <= tokenPerTransaction,
            "NFT: YOU_CAN_ONLY_A_FIXED_AMOUNT_OF_TOKENS"
        );
        uint256 _reserved = reservedTokens - reservedTokensCounter;
        require(
            totalSupply() + _amount + _reserved <= MaxSupply,
            "NFT: YOU_CAN_NOT_MINT_MORE_THAN_SUPPLY"
        );
        if (totalSupply() + _amount == MaxSupply) {
            contractStatus = ContractStatus.After;
        }
        if (tokensPerWallet[msg.sender] + _amount == tokenPerTransaction) {
            whitelist[msg.sender] = false;
        }
        for (uint256 i = 1; i <= _amount; i++) {
            uint256 _newID = totalSupply();

            tokensPerWallet[msg.sender] += 1;
            _safeMint(msg.sender, _newID);
            NFTInformation storage _nftInformation = nftInfos[_newID];
            _nftInformation.gender = "Man";
        }
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    /**
     * @dev mint tokens by the owner
     * @param _amount: the amount of tokens to mint by the owner
     */
    function mintByOwner(uint256 _amount) public onlyOwner {
        uint256 SUPPLY = totalSupply();
        require(contractStatus != ContractStatus.After, "NFT: SOLD_OUT");
        require(contractStatus == ContractStatus.Sale, "NFT: SALE_NOT_STARTED");
        require(_amount > 0, "NFT: YOU_NEED_TO_MINT_AT_LEAST_ONE_TOKEN");
        require(
            _amount <= tokenPerTransaction,
            "NFT: YOU_CAN_ONLY_A_FIXED_AMOUNT_OF_TOKENS"
        );
        require(
            reservedTokensCounter + _amount <= reservedTokens,
            "NFt: MAX_RESERVED_TOKENS_LIMIT_EXEEDED"
        );
        if (totalSupply() + _amount == MaxSupply) {
            contractStatus = ContractStatus.After;
        }
        reservedTokensCounter += _amount;
        for (uint256 i = 1; i <= _amount; i++) {
            uint256 _newID = totalSupply();
            _safeMint(msg.sender, _newID);
            NFTInformation storage _nftInformation = nftInfos[_newID];
            _nftInformation.gender = "Man";
        }
    }

    /**
     * @dev start the public sale
     */
    function startSale() external onlyOwner {
        contractStatus = ContractStatus.Sale;
    }

    /**
     * @dev change the reveal status to true
     */
    function revealNFTs() public onlyOwner {
        RevealStatus = true;
    }

    /**
     * @dev change the Not Revealed URL
     * @param _URI: The URL of the new not revealed
     */
    function setNotRevealedURI(string memory _URI) public onlyOwner {
        NotRevealedURI = _URI;
    }

    /**
     * @dev change the metadata URL
     * @param _URI: The URL of the new metadata
     */
    function setBaseURI(string memory _URI) public onlyOwner {
        BaseURI = _URI;
    }

    /**
     * @dev get the token metadata URL
     * @param _id: Token ID of the NFT
     */
    function tokenURI(uint256 _id)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (RevealStatus == false) {
            return NotRevealedURI;
        }
        return
            bytes(BaseURI).length > 0
                ? string(abi.encodePacked(BaseURI, _id.toString()))
                : "";
    }

    /**
     * @dev withdraw by Contract owner
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(developerAddress).transfer((balance * 10) / 100); // pay developer 10%
        uint256 _newBalance = address(this).balance;
        payable(msg.sender).transfer(_newBalance);
    }
}
