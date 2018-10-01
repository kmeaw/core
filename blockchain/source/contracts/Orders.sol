pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ProfileRegistry.sol";

contract Orders is Ownable {
    //events

    //enums

    enum OrderStatus {
        UNKNOWN,
        ORDER_INACTIVE,
        ORDER_ACTIVE
    }

    enum OrderType {
        ORDER_UNKNOWN,
        ORDER_BID,
        ORDER_ASK
    }

    //DATA
    struct Order {
        OrderInfo info;
        OrderParams params;
    }

    struct OrderInfo {
        OrderType orderType;
        address author;
        address counterparty;
        uint duration;
        uint price;
        bool[] netflags;
        ProfileRegistry.IdentityLevel identityLevel;
        address blacklist;
        bytes32 tag;
        uint64[] benchmarks;
        uint frozenSum;
    }

    struct OrderParams {
        OrderStatus orderStatus;
        uint dealID;
    }

    mapping(uint => Order) public orders;

    uint ordersAmount = 0;

    //Constructor

    constructor(address _market) public {
        owner = _market;
    }

    function Write(OrderType _orderType,
        OrderStatus _orderStatus,
        address _author,
        address _counterparty,
        uint _duration,
        uint256 _price,
        bool[] _netflags,
        ProfileRegistry.IdentityLevel _identityLevel,
        address _blacklist,
        bytes32 _tag,
        uint64[] _benchmarks,
        uint _frozenSum,
        uint _dealID) public onlyOwner  returns(uint) {

            ordersAmount += 1;

            orders[ordersAmount].info.orderType = _orderType;
            orders[ordersAmount].info.author = _author;
            orders[ordersAmount].info.counterparty = _counterparty;
            orders[ordersAmount].info.duration = _duration;
            orders[ordersAmount].info.price = _price;
            orders[ordersAmount].info.netflags = _netflags;
            orders[ordersAmount].info.identityLevel = _identityLevel;
            orders[ordersAmount].info.blacklist = _blacklist;
            orders[ordersAmount].info.tag = _tag;
            orders[ordersAmount].info.benchmarks = _benchmarks;
            orders[ordersAmount].info.frozenSum = _frozenSum;
            orders[ordersAmount].params.orderStatus = _orderStatus;
            orders[ordersAmount].params.dealID = _dealID;

            return ordersAmount;
        }

    function SetOrderStatus(uint orderID, OrderStatus _status) public onlyOwner {
        require(orderID >= ordersAmount);
        orders[orderID].params.orderStatus = _status;
    }

    function SetOrderDealID(uint orderID, uint _dealID) public onlyOwner {
        require(orderID >= ordersAmount);
        orders[orderID].params.orderStatus = OrderStatus.ORDER_INACTIVE;
        //dont think that Is really necessary emit event here
    }

    function GetOrdersAmount() public view returns (uint) {
        return ordersAmount;
    }

    function GetOrderInfo(uint orderID) view public
    returns (
        OrderType orderType,
        address author,
        address counterparty,
        uint duration,
        uint price,
        bool[] netflags,
        ProfileRegistry.IdentityLevel identityLevel,
        address blacklist,
        bytes32 tag,
        uint64[] benchmarks,
        uint frozenSum
    ){
        OrderInfo memory info = orders[orderID].info;
        return (
        info.orderType,
        info.author,
        info.counterparty,
        info.duration,
        info.price,
        info.netflags,
        info.identityLevel,
        info.blacklist,
        info.tag,
        info.benchmarks,
        info.frozenSum
        );
    }

    function GetOrderParams(uint orderID) view public
    returns (
        OrderStatus orderStatus,
        uint dealID
    ){
        OrderParams memory params = orders[orderID].params;
        return (
        params.orderStatus,
        params.dealID
        );
    }

}
