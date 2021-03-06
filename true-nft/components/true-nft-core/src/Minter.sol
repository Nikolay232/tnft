pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/INftRoot.sol';

contract Minter {

    uint256 public adminPubkey;
    address adminAddress;

    address _addrRoot;

    uint256 public maxMint; // Maximum number of tokens to mint. The token with this number will not be minted
    uint256 public totalMinted; // Current number of tokens minted.
    uint128 public MINT_FEE = 2 ton;

    mapping(uint256 => string) _images;
    mapping(uint256 => string) _metadatas;

    modifier onlyAdmin() {
        require( (msg.pubkey() == adminPubkey) || (msg.sender == adminAddress), 100);
        tvm.accept();
        _;
    }

    constructor(address addrRoot, mapping(uint256 => string) images, mapping(uint256 => string) metadatas, uint256 _maxMint) public {
        tvm.accept();
        _addrRoot = addrRoot;
        adminPubkey = msg.pubkey();
        _images = images;
        _metadatas = metadatas;
        maxMint = _maxMint;
    }

    function mintNft() public {
        require(msg.value >= MINT_FEE, 201);
        require(totalMinted < maxMint, 202);


        _addrRoot.transfer(1.1 ton); // Transfer 1.1 Ever to pay deploy gas fees
        INftRoot(_addrRoot).mintNftToUser(msg.sender, _images[totalMinted], _metadatas[totalMinted]  );

        totalMinted++;
    }

    function mintNftAdmin() public onlyAdmin {
        INftRoot(_addrRoot).mintNftToUser(msg.sender, _images[totalMinted], _metadatas[totalMinted]  );
        totalMinted++;
    }

    function setTotalMinted(uint128 _totalMinted) public onlyAdmin {
        totalMinted = _totalMinted;
    }

    function setMaxMint(uint128 _maxMint) public onlyAdmin {
        maxMint = _maxMint;
    }

    function setMintFee(uint128 _newFee) public onlyAdmin {
        MINT_FEE = _newFee;
    }

    function transferAdmin(uint256 _newAdminPubkey, address _newAdminAddress) public onlyAdmin {
        adminPubkey = _newAdminPubkey;
        adminAddress = _newAdminAddress;
    }

    function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) public onlyAdmin {
        dest.transfer(value, bounce, flags, payload);
    }

}