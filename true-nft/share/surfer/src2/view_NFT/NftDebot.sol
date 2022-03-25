pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../../../../components/debots/Interfaces/Debot.sol";
import "../../../../components/debots/Interfaces/Terminal.sol";
import "../../../../components/debots/Interfaces/Menu.sol";
import "../../../../components/debots/Interfaces/Msg.sol";
import "../../../../components/debots/Interfaces/ConfirmInput.sol";
import "../../../../components/debots/Interfaces/AddressInput.sol";
import "../../../../components/debots/Interfaces/NumberInput.sol";
import "../../../../components/debots/Interfaces/AmountInput.sol";
import "../../../../components/debots/Interfaces/Sdk.sol";
import "../../../../components/debots/Interfaces/Upgradable.sol";
import "../../../../components/debots/Interfaces/UserInfo.sol";
import "../../../../components/debots/Interfaces/SigningBoxInput.sol";
import "https://raw.githubusercontent.com/tonlabs/DeBot-IS-consortium/main/Media/Media.sol";

import "./NftRoot.sol";
import "./IndexBasis.sol";
import "./Data.sol";
import "./Index.sol";

interface IMultisig {
    function submitTransaction(
        address dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload)
    external returns (uint64 transId);

    function sendTransaction(
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload)
    external;
}

struct RootParams {
    address addrOwner;
    string name;
    string description;
    string tokenCode;
    uint256 totalSupply;
    uint128 index;
    bytes part;
}

struct TransferParams {
    address addrIndex;
    address addrData;
    address addrTo;
}

struct NftParams {
    uint64 creationDate;
    string comment;
    address owner;
}

struct NftResp {
    address addrData;
    address owner;
    string content;
    string content1;
    string content2;
    string content3;
}

// contract NftDebot is Debot, Upgradable {
contract NftDebot is Debot {

    // TvmCell _codeNFTRoot;
    TvmCell _codeBasis;
    TvmCell _codeData;
    TvmCell _codeIndex;

    address _addrNFTRoot;
    uint256 _totalMinted;

    // bytes _surfContent;

    address _addrMultisig;
    // address _addrManager;

    uint32 _keyHandle;

    uint128 _price;

    // TransferParams _transferParams;
    // NftParams _nftParams;
    NftResp[] _owners;

    modifier accept {
        tvm.accept();
        _;
    }

    /*
    * Uploaders
    */

    function setBasisCode(TvmCell code) public accept {
        _codeBasis = code;
    }
    function setDataCode(TvmCell code) public accept {
        _codeData = code;
    }
    function setIndexCode(TvmCell code) public accept {
        _codeIndex = code;
    }
    function setNFTRoot(address addr) public accept {
        _addrNFTRoot = addr;
    }

    /*
     *  Overrided Debot functions
     */

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Medal admin Debot";
        version = "1.0.0";
        publisher = "";
        key = "";
        author = "";
        support = address.makeAddrStd(0, 0x0);
        hello = "Hello, I'm Medal admin DeBot";
        language = "en";
        dabi = m_debotAbi.get();
        icon = "";
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, SigningBoxInput.ID, ConfirmInput.ID, AmountInput.ID,  Media.ID ];
    }

    function start() public override {
        mainMenu(0);
    }

    function mainMenu(uint32 index) public {
        index;
        if(_addrMultisig == address(0)) {
            Terminal.print(0, 'You need to attach Multisig');
            attachMultisig();
        } else {
            restart();
        }
    }
    function restart() public {
        Terminal.print(0, format('restart==_keyHandle: {}', _keyHandle));
        if(_keyHandle == 0) {
            uint[] none;
            SigningBoxInput.get(tvm.functionId(setKeyHandle), "Enter keys to sign all operations.", none);
            return;
        }
        // resolveNFTRoot();
        checkContract(_addrNFTRoot);
    }
    function checkContract(address addr) public {
//        Terminal.print(0, format('checkContract: {}', addr));
        Sdk.getAccountType(tvm.functionId(checkRootContract), addr);
    }
    function checkRootContract(int8 acc_type) public {
        MenuItem[] _items;
        _items.push(MenuItem("Get all Nft(text)", "", tvm.functionId(getAllNftDataText)));
        _items.push(MenuItem("Get all Nft(image)", "", tvm.functionId(getAllNftDataImage)));
        _items.push(MenuItem("Get my Nft(text)", "", tvm.functionId(getMyAllNftDataText)));
        _items.push(MenuItem("Get my Nft(image)", "", tvm.functionId(getMyAllNftDataImage)));
        Menu.select("==What to do?==", "", _items);
    }

   function getAllNftDataText(uint32 index) public {
       index;
       delete _owners;
       TvmBuilder salt;
       salt.store(_addrNFTRoot);
       TvmCell code = tvm.setCodeSalt(_codeData.toSlice().loadRef(), salt.toCell());
       uint256 codeHashNftData = tvm.hash(code);
       Sdk.getAccountsDataByHash(tvm.functionId(getNftDataByHash), codeHashNftData, address(0x98ccdd72fa6eb4964e2095d04d1c0a57e183921d23c40c206149499dea88361e));
   }
   function getNftDataByHash(ISdk.AccData[] accounts) public {
       for (uint i = 0; i < accounts.length; i++)
       {
           getNftData(accounts[i].id);
       }
       this.printNftData();
   }
   function getNftData(address addrData) public {
       Data(addrData).getOwner{
           abiVer: 2,
           callbackId: tvm.functionId(setNftData),
           onErrorId: 0,
           time: 0,
           expire: 0,
           sign: false
       }().extMsg;
   }
   function setNftData(address addrOwner, address addrData, string content, string content1, string content2, string content3) public {
       _owners.push(NftResp(addrData, addrOwner, content, content1, content2, content3));
   }
   function printNftData() public {
       for (uint i = 0; i < _owners.length; i++) {
           Terminal.print(0, format("Index: {}\nNft: {}\nOwner: {}\n", i, _owners[i].addrData, _owners[i].owner));
           string str = _buildNftDataPrint(i, _owners[i].addrData, _owners[i].owner, _owners[i].content, _owners[i].content1, _owners[i].content2, _owners[i].content3);
           Terminal.print(0, str);
       }
       MenuItem[] items;
       items.push(MenuItem("Return to main menu:", "", tvm.functionId(mainMenu)));
    //    items.push(MenuItem("Burn nft", "", tvm.functionId(burnOneNft)));
       Menu.select("==What to do?==", "", items);
   }
   function _buildNftDataPrint(uint id, address nftData, address ownerAddress, string content, string content1, string content2, string content3) public returns (string str) {
    //    str = format("Index: {}\nNft: {}\nOwner: {}\nContent: {}\nContent1: {}\nContent2: {}\nContent3: {}\n", id, nftData, ownerAddress, content, content1, content2, content3);
       str = "data:image/jpeg;base64," + content + content1 + content2 + content3;
   }

//-----------------------------------------------------------------------------------------------------------------------
      function getAllNftDataImage(uint32 index) public {
       index;
       delete _owners;
       TvmBuilder salt;
       salt.store(_addrNFTRoot);
       TvmCell code = tvm.setCodeSalt(_codeData.toSlice().loadRef(), salt.toCell());
       uint256 codeHashNftData = tvm.hash(code);
       Sdk.getAccountsDataByHash(tvm.functionId(getNftDataByHashImage), codeHashNftData, address(0x0));
   }
   function getNftDataByHashImage(ISdk.AccData[] accounts) public {
       for (uint i = 0; i < accounts.length; i++)
       {
           getNftDataImage(accounts[i].id);
       }
       this.printMyNftDataImage();
   }
   function getNftDataImage(address addrData) public {
       Data(addrData).getOwner{
           abiVer: 2,
           callbackId: tvm.functionId(setNftDataImage),
           onErrorId: 0,
           time: 0,
           expire: 0,
           sign: false
       }().extMsg;
   }
   function setNftDataImage(address addrOwner, address addrData, string content, string content1, string content2, string content3) public {
       _owners.push(NftResp(addrData, addrOwner, content, content1, content2, content3));
   }
   function printMyNftDataImage() public {
       for (uint i = 0; i < _owners.length; i++) {
           Terminal.print(0, format("Index: {}\nNft: {}\nOwner: {}\n", i, _owners[i].addrData, _owners[i].owner));
           string str = _buildNftDataPrint(i, _owners[i].addrData, _owners[i].owner, _owners[i].content, _owners[i].content1, _owners[i].content2, _owners[i].content3);
        //    Terminal.print(0, str);
           Media.output(
               tvm.functionId(setResult),
               "",
               str
           );
       }
       MenuItem[] items;
       items.push(MenuItem("Return to main menu:", "", tvm.functionId(mainMenu)));
    //    items.push(MenuItem("Burn nft", "", tvm.functionId(burnOneNft)));
       Menu.select("==What to do?==", "", items);
   }


//-----------------------------------------------------------------------------------------------------------------------
   function getMyAllNftDataText(uint32 index) public {
       index;
       delete _owners;
       TvmBuilder salt;
       salt.store(_addrNFTRoot);
       TvmCell code = tvm.setCodeSalt(_codeData.toSlice().loadRef(), salt.toCell());
       uint256 codeHashNftData = tvm.hash(code);
       Sdk.getAccountsDataByHash(tvm.functionId(getMyNftDataByHashText), codeHashNftData, address(0x0));
   }
   function getMyNftDataByHashText(ISdk.AccData[] accounts) public {
       for (uint i = 0; i < accounts.length; i++)
       {
           getMyNftDataText(accounts[i].id);
       }
       this.printNftDataImage(false);
   }
   function getMyNftDataText(address addrData) public {
       Data(addrData).getOwner{
           abiVer: 2,
           callbackId: tvm.functionId(setMyNftDataText),
           onErrorId: 0,
           time: 0,
           expire: 0,
           sign: false
       }().extMsg;
   }
   function setMyNftDataText(address addrOwner, address addrData, string content, string content1, string content2, string content3) public {
       _owners.push(NftResp(addrData, addrOwner, content, content1, content2, content3));
   }

   function getMyAllNftDataImage(uint32 index) public {
       index;
       delete _owners;
       TvmBuilder salt;
       salt.store(_addrNFTRoot);
       TvmCell code = tvm.setCodeSalt(_codeData.toSlice().loadRef(), salt.toCell());
       uint256 codeHashNftData = tvm.hash(code);
       Sdk.getAccountsDataByHash(tvm.functionId(getMyNftDataByHashImage), codeHashNftData, address(0x0));
   }
   function getMyNftDataByHashImage(ISdk.AccData[] accounts) public {
       for (uint i = 0; i < accounts.length; i++)
       {
           getMyNftDataImage(accounts[i].id);
       }
       this.printNftDataImage(true);
   }
   function getMyNftDataImage(address addrData) public {
       Data(addrData).getOwner{
           abiVer: 2,
           callbackId: tvm.functionId(setMyNftDataImage),
           onErrorId: 0,
           time: 0,
           expire: 0,
           sign: false
       }().extMsg;
   }
   function setMyNftDataImage(address addrOwner, address addrData, string content, string content1, string content2, string content3) public {
       _owners.push(NftResp(addrData, addrOwner, content, content1, content2, content3));
   }
   function printNftDataImage(bool _is_image) public {
       for (uint i = 0; i < _owners.length; i++) {
           if (_owners[i].owner == _addrMultisig) { 
               Terminal.print(0, format("Index: {}\nNft: {}\nOwner: {}\n", i, _owners[i].addrData, _owners[i].owner));
               string str = _buildNftDataPrint(i, _owners[i].addrData, _owners[i].owner, _owners[i].content, _owners[i].content1, _owners[i].content2, _owners[i].content3);
               if (_is_image) {
                    Media.output(
                        tvm.functionId(setResult),
                        "",
                        str
                    );
               } else {
                   Terminal.print(0, str);
               }
               
           }
       }
       MenuItem[] items;
       items.push(MenuItem("Return to main menu:", "", tvm.functionId(mainMenu)));
    //    items.push(MenuItem("Burn nft", "", tvm.functionId(burnOneNft)));
       Menu.select("==What to do?==", "", items);
   }

   function setResult(MediaStatus result) public pure {
       // require(result == MediaStatus.Success);
       // _start();
   }

    /*
    * helpers
    */

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Sdk error {}. Exit code {}.", sdkError, exitCode));
        restart();
    }

    function attachMultisig() public {
        AddressInput.get(tvm.functionId(saveMultisig), "Attach Multisig\nEnter address:");
    }

    function saveMultisig(address value) public {
        Terminal.print(0, format('saveMultisig: {}', value));
        _addrMultisig = value;
        Terminal.print(0, format('_addrMultisig: {}', _addrMultisig));
        restart();
    }

    function setKeyHandle(uint32 handle) public {
        Terminal.print(0, 'You need to attach Multisig');
        Terminal.print(0, format('_keyHandle: {}', handle));
        _keyHandle = handle;
        restart();
    }

}