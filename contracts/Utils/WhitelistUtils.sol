//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WhitelistUtils is Ownable {
    bool public preSale;
    bool public preSaleT;

    bytes32 private root;
    bytes32 private rootT;
    bytes32 private rootFreeMint;

    mapping (address => bool) preSaleClaimed;
    mapping (address => bool) preSaleTClaimed;
    mapping (address => bool) freeMintClaimed;

    // ---------------- MERKLE PROOF ------------------------ //
    
    function isValid(bytes32[] memory proof, bytes32 leaf) private view returns(bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function isValidT(bytes32[] memory proof, bytes32 leaf) private view returns(bool) {
        return MerkleProof.verify(proof, rootT, leaf);
    }

    function isValidFreeMint(bytes32[] memory proof, bytes32 leaf) private view returns(bool) {
        return MerkleProof.verify(proof, rootFreeMint, leaf);
    }

    function setRoot(bytes32 _root) external onlyOwner{
        root = _root;
    }

    function setRootT(bytes32 _root) external onlyOwner{
        rootT = _root;
    }

    function setRootFreeMint(bytes32 _root) external onlyOwner{
        rootFreeMint = _root;
    }

    // -------------------------------------------------- //

    // --------------------------------------------------- //

    //getters
    function isPresaleClaimed(address _address) public view returns(bool){
        return preSaleClaimed[_address];
    }

    function isPresaleTClaimed(address _address) public view returns(bool){
        return preSaleTClaimed[_address];
    }

    function isFreeMintClaimed(address _address) public view returns(bool){
        return freeMintClaimed[_address];
    }

    function isPresaleOn() internal view returns(bool){
        if(preSale || preSaleT){
            return true;
        }
        else{
            return false;
        }
    }

    // setters

    function setPresaleClaimed(address _address) private {
        preSaleClaimed[_address] = true;
    }

    function setPresaleTClaimed(address _address) private {
        preSaleTClaimed[_address] = true;
    }

    function setFreeMintClaimed(address _address) private {
        freeMintClaimed[_address] = true;
    }

    function setPresaleOn(bool _preSale) external onlyOwner{
        if(_preSale){
            preSale = true;
            if(preSaleT) {
                preSaleT = false;
            }
        }
        else {
            if(preSale) {
                preSale = false;
            }
            preSaleT = true;
        }
    }

    function setPresaleOff() external onlyOwner {
        preSale = false;
        preSaleT = false;
    }
    
    // --------------------------------------------------- //

    // ------------------- MINT -------------------------- //
    function presaleCheck(bytes32[] memory proof, bool _freeMint) internal {
        if(_freeMint){
            freeMintCheck(proof);
        }
        else{
            whitelistMintCheck(proof);
        }
    }


    function freeMintCheck(bytes32[] memory proof) private {
        require(isValidFreeMint(proof, keccak256(abi.encodePacked(_msgSender()))), "YOU ARE NOT A CHOSEN ONE");
        require(!isFreeMintClaimed(_msgSender()), "You have already claimed.");
        setFreeMintClaimed(_msgSender());
    }

    function whitelistMintCheck(bytes32[] memory proof) private{
        require(preSaleT || preSale, "THE GATES ARE CLOSED");

        if(preSaleT){
            require(isValidT(proof, keccak256(abi.encodePacked(_msgSender()))), "THE GATES ONLY OPEN FOR THE CHOSEN ONES");
            require(!isPresaleTClaimed(_msgSender()), "You have already claimed");
            setPresaleTClaimed(_msgSender());
        }
        else if (preSale){
            require(isValid(proof, keccak256(abi.encodePacked(_msgSender()))), "THE GATES ONLY OPEN FOR THE CHOSEN ONES");
            require(!isPresaleClaimed(_msgSender()), "You have already claimed");
            setPresaleClaimed(_msgSender());
        }
    }
}