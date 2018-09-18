pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Orders() is Ownable{
    //events

    event OrderPlaced(uint indexed orderID);
    event OrderUpdated(uint indexed orderID);

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

    constructor(address _market) {
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
        uint _dealID) public onlyOwner {

            ordersAmount = ordersAmount.add(1);
            uint256 orderId = ordersAmount;

            orders[orderId] = Order(_orderType,
                _orderStatus,
                _author,
                _counterparty,
                _duration,
                _price,
                _netflags,
                _identityLevel,
                _blacklist,
                _tag,
                _benchmarks,
                _frozenSum,
                _dealID);

            emit OrderPlaced(orderId);
        }

    function Cancel(orderID) public onlyOwner {
        require(orderID >= ordersAmount);
        orders[orderID].OrderParams.orderStatus = OrderStatus.ORDER_INACTIVE;
        emit OrderUpdated(orderID);
    }

    function BindDeal(orderID, dealID) public onlyOwner {
        require(orderID >= ordersAmount);
        orders[orderID].OrderParams.orderStatus = OrderStatus.ORDER_INACTIVE;
        //dont think that really necessary emit event here
    }

    function getOrdersAmount() public view returns (uint) {
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
        Order.Info memory info = orders[orderID].OrderInfo;
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
        Order memory params = orders[orderID].OrderParams;
        return (
        params.orderStatus,
        params.dealID
        );
    }

}
