// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
// import ERC721 Token and ownable smart contract code used for owner access
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  // Tuple Created for defining an address of nft as well as id so 
  // that we can keep track of each air drop
  struct Airdrop {
    address nft;
    uint id;
  }
  // variable we will be using in our smart contract
  using Strings for uint256;
  string public baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 10000;
  uint public nextAirdropId;
  address public admin;
  mapping(uint => Airdrop) public airdrops;
//   checking if the recipients is approved or not
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

  // public mint function used for mint 
  function mint(address _to, uint256 _mintAmount) public payable {
// getting total supply from totalSupplyy Function and checking mint amount should be > 0
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    // supply + _mintAmount cannot be > max supply logically
    require(supply + _mintAmount <= maxSupply);
    _safeMint(_to, _mintAmount);
  }


// setters for setting admin wallet address and setting baseURI
  function setAdmin(address _newAdmin) public onlyAdmin {
    admin = _newAdmin;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
// adding AirDrops in array form 
// external modifier means only accesible outside smart contract
  function addAirdrops(Airdrop[] memory _airdrops) external {
    uint _nextAirdropId = nextAirdropId;
    // looping over passed array
    for(uint i = 0; i < _airdrops.length; i++) {
      airdrops[_nextAirdropId] = _airdrops[i];
    //   usingERC721 token method transfering token from caller of the function to our address
    // later smart contract will do air drop
      IERC721(_airdrops[i].nft).transferFrom(
        msg.sender, 
        address(this), 
        _airdrops[i].id
      );
      _nextAirdropId++;
    }
  }

//adding reciepients into an approved state
// by changing its mapping created earlier
  function addRecipients(address[] memory _recipients) external onlyAdmin{
    for(uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = true;
    }
  }
// adding and removing recepients are because if some one not claim airdrop in gine span
// we'll remove them
// i.e false
  function removeRecipients(address[] memory _recipients) external onlyAdmin{
    for(uint i = 0; i < _recipients.length; i++) {
      recipients[_recipients[i]] = false;
    }
  }

//  claiming air drops
  function claim() external {
    //checking if this address is in reciepients mapping 
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