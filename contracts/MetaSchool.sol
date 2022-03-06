// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  struct Airdrop {
    address nft;
    uint id;
  }
  using Strings for uint256;
  string public baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 10000;
  uint public nextAirdropId;
  address public admin;
  mapping(uint => Airdrop) public airdrops;
  mapping(address => bool) public recipients;

  constructor() 
  ERC721("MetaSchool", "MS") {
    setBaseURI("ipfs://QmbjasGHWhDyizG1YJYZAjiLp2gPtVs8ktGiqYnfbj5Di4");
    admin = msg.sender;
  }

  modifier onlyAdmin{
    require(admin == msg.sender);
    _;
  }
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(supply + _mintAmount <= maxSupply);
    _safeMint(_to, _mintAmount);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    // bytes(currentBaseURI).length means if currentBaseURI has something init
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setAdmin(address _newAdmin) public onlyAdmin {
    admin = _newAdmin;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function addAirdrops(Airdrop[] memory _airdrops) external {
    uint _nextAirdropId = nextAirdropId;
    for(uint i = 0; i < _airdrops.length; i++) {
      airdrops[_nextAirdropId] = _airdrops[i];
      IERC721(_airdrops[i].nft).transferFrom(
        msg.sender, 
        address(this), 
        _airdrops[i].id
      );
      _nextAirdropId++;
    }
  }

  function addRecipients(address[] memory _recipients) external onlyAdmin{
    for(uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = true;
    }
  }

  function removeRecipients(address[] memory _recipients) external onlyAdmin{
    for(uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = false;
    }
  }

  function claim() external {
    require(recipients[msg.sender] == true, 'recipient not registered');
    recipients[msg.sender] = false;
    Airdrop storage airdrop = airdrops[nextAirdropId];
    IERC721(airdrop.nft).transferFrom(address(this), msg.sender, airdrop.id);
    nextAirdropId++;
  }
  function withdraw() public payable onlyOwner {
    // This will payout the owner 95% of the contract balance.
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}