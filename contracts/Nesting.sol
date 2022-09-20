// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "./Utils/MintingUtils.sol";
import "./Utils/WhitelistUtils.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/equippable/RMRKNestingExternalEquip.sol";

contract Nesting is MintingUtils, WhitelistUtils, RMRKNestingExternalEquip, ReentrancyGuard {
    using Counters for Counters.Counter;

    address _equippableAddress;

    uint256 public maxMintAmountPerTx = 20;
    uint256 private RESERVED_NFT = 33;

    bool public reservedNFTMinted;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 mintPrice_,
        address equippableAddress_
    )
        RMRKNestingExternalEquip(name_, symbol_)
        MintingUtils(maxSupply_, mintPrice_)
    {
        _equippableAddress = equippableAddress_;
    }

    // --------------- MINT -------------------------- //

    modifier mintReq (uint256 numberOfTokens) {
        require(!isPresaleOn(), "Presale is going on");
        if(!reservedNFTMinted){
            require((totalSupply() + numberOfTokens) <= (maxSupply() - RESERVED_NFT), "Not enough tokens left.");
        }
        else{
            require((totalSupply() + numberOfTokens) <= maxSupply(), "Not enough tokens left.");
        }
        require(numberOfTokens <= maxMintAmountPerTx && numberOfTokens > 0, "Max mint amount per transaction is 20.");   
        require(msg.value >= (mintPrice() * numberOfTokens), "Not enough ether sent.");
        _;
    }

    function reserveNFT() external onlyOwner {
      if (reservedNFTMinted) revert ("Reserved NFTs already minted");
      for(uint i = 0; i< RESERVED_NFT;) {
          _tokenIdTracker.increment();
          uint256 currentToken = _tokenIdTracker.current();
          _safeMint(owner(), currentToken);
          unchecked {++i;}
      }
      reservedNFTMinted = true;
    }

    function mint(uint256 numberOfTokens) external payable saleIsOpen mintReq(numberOfTokens) nonReentrant {
        for(uint i = 0; i< numberOfTokens;) {
            if(totalSupply() < maxSupply()){
                _tokenIdTracker.increment();
                uint256 currentToken = _tokenIdTracker.current();
                _safeMint(_msgSender(), currentToken);
                unchecked {++i;}
            }
        }
    }

    function mintNesting(
        address to,
        uint256 numberOfTokens,
        uint256 destinationId
    ) external payable mintReq(numberOfTokens) saleIsOpen {
        for(uint i = 0; i< numberOfTokens;) {
            if(totalSupply() < maxSupply()){
                _tokenIdTracker.increment();
                uint256 currentToken = _tokenIdTracker.current();
                _nestMint(to, currentToken, destinationId);
                unchecked {++i;}
            }
        }
    }

    function presaleMint(bytes32[] memory proof, bool _freeMint) public payable nonReentrant saleIsOpen {
        if(!_freeMint){
            require(msg.value >= mintPrice(), "Not enough ether sent.");
        }
        presaleCheck(proof, _freeMint);
        
        _tokenIdTracker.increment();
        uint256 currentToken = _tokenIdTracker.current();
        _safeMint(_msgSender(), currentToken);
    }

    // ------------------------------------------------ //

    // ---------------- WALLET OF OWNER ------------------------- //

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply()) {
        address currentTokenOwner = ownerOf(currentTokenId);

        if (currentTokenOwner == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentTokenId;

            ownedTokenIndex++;
        }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    // ------------------------------------------------ //


    //update for reentrancy
    function burn(uint256 tokenId) public onlyApprovedOrDirectOwner(tokenId) {
        _burn(tokenId);
    }

    function setEquippableAddress(address equippable) external onlyOwner {
        _setEquippableAddress(equippable);
    }
}
