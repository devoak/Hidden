// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

contract Oasis is ERC721A, Ownable, ERC2981 {
    bool public isWhitelistSaleActive = false;
    bool public isPublicSaleActive = false;
    bool public revealed = false;

    string private baseURI;
    string private baseContractDataUri;
    uint public maxSupply = 10000;
    uint public whitelistSupply = 3000;
    uint public publicMintCost = 1 ether;
    uint public whitelistMintCost = .5 ether;
    uint96 defaultRoyaltyPercentage = 5;
    bytes32 merkleRoot;

    mapping(address => bool) private usedWL;

    constructor(string memory _baseNftUri, string memory _baseContractDataUri, bytes32 _merkleRoot) ERC721A("Hidden", "NameHidden") {
        baseURI = _baseNftUri;
        baseContractDataUri = _baseContractDataUri;
        merkleRoot = _merkleRoot;

        setDefaultRoyalty(address(this), defaultRoyaltyPercentage);
    }

    function setDefaultRoyalty(address receiver, uint96 royaltyPercentage) public onlyOwner {
        _setDefaultRoyalty(receiver, royaltyPercentage * 100);
    }

    function checkIsAddressInWl(bytes32[] memory _merkleProof) public view returns(bool) {
        return MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }
    
    function publicMint() public payable {
        require(totalSupply() + 1 <= maxSupply, "All NFT have already been minted!");
        require(isPublicSaleActive == true, "Public sale is inactive!");
        require(msg.value >= publicMintCost, "You are trying to pay the wrong amount");

        _safeMint(msg.sender, 1);
    }

    function whitelistMint(bytes32[] memory _merkleProof) public payable {
        require(totalSupply() + 1 <= whitelistSupply, "All NFT for WL have already been minted!");
        require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))) == true, "Failed merkle proof!");
        require(isWhitelistSaleActive, "Whitelist sale is inactive!");
        require(msg.value >= whitelistMintCost, "You are trying to pay the wrong amount");
        require(usedWL[msg.sender] == false, "You already minted!");

        _safeMint(msg.sender, 1);
        usedWL[msg.sender] = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
        
    function setWlMintPrice(uint _newPrice) public onlyOwner {
        whitelistMintCost = _newPrice;
    }

    function setPublicMintPrice(uint _newPrice) public onlyOwner {
        publicMintCost = _newPrice;
    }
    
    function togglePublicSale() public onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleWhitelistSale() public onlyOwner {
        isWhitelistSaleActive = !isWhitelistSaleActive;
    }

    function toggleReveal(string memory baseURI_) public onlyOwner {
        revealed = !revealed;
        baseURI = baseURI_;
    }

    function withdrawMoney() public onlyOwner {
        address payable _to = payable(owner());
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (revealed) return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
        else return string(abi.encodePacked(baseURI, "hidden"));
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns(bool){
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseContractDataUri, "contract_data"));
    }
} 