// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma experimental ABIEncoderV2;
contract MediCare{

    struct medicine{
        uint256 id;
        string name;
        string image;
        address owner;
        uint256 price;
        uint256 stock;
    }

    struct Manufacturer{
        bool isRegister;
        string name;
    }

    constructor(){
        owner=msg.sender;
    }

    address private owner;
    mapping(uint256=>medicine) public medicines;
    mapping(string=>uint256[]) private mediindex;
    mapping(address=>Manufacturer) public manufacturers;
    uint256 public totalmedicines;
    uint256 TotalManufacturers;
    mapping(uint256=>address) public TotalManufacturer;

    event manufacturerevent(address indexed manufacturer,string name);
    event registermedievent(uint256 indexed id,string name,string image,address indexed owner,uint256 price,uint256 stock);
    event updatepriceevent(uint256 indexed id,uint256 price);
    event updatestockevent(uint256 indexed id,uint256 stock);
    event buymedibyNameevent(string name,address indexed buyer,address indexed seller);
    event buymedibyIdevent(uint256 indexed id,address indexed buyer,address indexed seller);

    modifier OnlyOwn{
        require(msg.sender==owner,"Only owner can perform the actions");
        _;
    }

    modifier Onlymanufacturer{
        require(manufacturers[msg.sender].isRegister);
        _;
    }

    function registerManufacturer(address manu,string memory name) public OnlyOwn{
        require(manufacturers[manu].isRegister==false,"Manufacturer already registerd");
        manufacturers[manu]=Manufacturer(true,name);
        TotalManufacturers+=1;
        uint256 id=TotalManufacturers;
        TotalManufacturer[id]=manu;
        emit manufacturerevent(manu,name);
    }

    function registermedicine(string memory name,string memory image,uint256 price,uint256 stock) public Onlymanufacturer {
        uint256 id=totalmedicines+1;
        medicine memory newmedi=medicine(id,name,image,msg.sender,price,stock);
        medicines[id]=newmedi;
        mediindex[name].push(id);
        totalmedicines++;
        emit registermedievent(id,name,image,msg.sender,price,stock);
    }

    function updateprice(uint256 id,uint256 price) public {
        require(medicines[id].id==id,"No medicine is registered on this id");
        require(medicines[id].owner==msg.sender,"Only the owner can set the medicine price");
        medicines[id].price=price;
        emit updatepriceevent(id, price);
    }
    function updatestock(uint256 id,uint256 stock) public {
        require(medicines[id].id==id,"No medicine is registered on this id");
        require(medicines[id].owner==msg.sender,"Only the owner can set the medicine price");
        medicines[id].stock=stock;
        emit updatestockevent(id, stock);
    }

    function getPrice(string memory name) public view returns (uint[] memory,uint256[] memory){
        uint256[] memory mediIds=mediindex[name];
        require(mediIds.length>0,"Medicine not found");
        uint256[] memory prices=new uint256[](mediIds.length);
        for(uint256 i=0;i<mediIds.length;i++){
            uint256 id=mediIds[i];
            prices[i]=medicines[id].price;
        }
        return (mediIds,prices);
    }


    function buymedicinebyName(string memory name) public payable {
        uint256[] memory mediIds=mediindex[name];
        require(mediIds.length>0,"Medicine not found");
        uint256 mediId=mediIds[0];   //Assume only one medi exists with the given name
        medicine storage medi=medicines[mediId];
        require(medi.owner!=address(0),"Invalid");
        require(medi.owner!=msg.sender,"You can't buy your own medicine");
        require(medi.price>0,"Medicine price not set");
        require(msg.value>=medi.price,"Insufficient");
        address payable seller=payable(medi.owner);
        seller.transfer(msg.value);
        emit buymedibyNameevent(name, msg.sender, seller);
    }

    function buymedicinebyIndex(uint256[] memory ids,uint256[] memory num)public payable {
        require(ids.length>0,"No medicine ids provided");
        require(ids.length==num.length,"You are not providing the number of medicines");
        uint256 totalprice=0;
        for(uint256 i=0;i<ids.length;i++){
            uint256 id=ids[i];
            require(medicines[id].id==id,"Medicine does not exist");
            medicine storage medi=medicines[id];
            require(medi.owner!=address(0),"Invalid");
            require(medi.owner!=msg.sender,"You can't buy your own medicine");
            require(medi.price>0,"Medicine price not set");
            totalprice+=(medi.price*num[i]);
        }
        require(msg.value>=totalprice);
        for(uint256 i=0;i<ids.length;i++){
            uint256 id=ids[i];
            medicine storage medi=medicines[id];
            address payable seller=payable(medi.owner);
            seller.transfer(medi.price*num[i]);
            emit buymedibyIdevent(id,msg.sender, seller);
        }
    }
    function getmedicines() public view returns(medicine[] memory){
        medicine[] memory res=new medicine[](totalmedicines);
        for(uint i=0;i<totalmedicines;i++){
            res[i]=medicines[i];
        }
        return res;
    }
}
