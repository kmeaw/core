pragma solidity ^0.4.23;


import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./SNM.sol";
import "./Blacklist.sol";
import "./OracleUSD.sol";
import "./ProfileRegistry.sol";
import "./Administratum.sol";


contract Market is Ownable, Pausable {

    using SafeMath for uint256;

    // DECLARATIONS

    enum DealStatus{
        STATUS_UNKNOWN,
        STATUS_ACCEPTED,
        STATUS_CLOSED
    }

    enum RequestStatus {
        REQUEST_UNKNOWN,
        REQUEST_CREATED,
        REQUEST_CANCELED,
        REQUEST_REJECTED,
        REQUEST_ACCEPTED
    }

    enum BlacklistPerson {
        BLACKLIST_NOBODY,
        BLACKLIST_WORKER,
        BLACKLIST_MASTER
    }

    struct Deal {
        uint64[] benchmarks;
        address supplierID;
        address consumerID;
        address masterID;
        uint askID;
        uint bidID;
        uint duration;
        uint price; //usd * 10^-18
        uint startTime;
        uint endTime;
        DealStatus status;
        uint blockedBalance;
        uint totalPayout;
        uint lastBillTS;
    }


    struct ChangeRequest {
        uint dealID;
        OrderType requestType;
        uint price;
        uint duration;
        RequestStatus status;
    }

    // EVENTS

    event DealOpened(uint indexed dealID);
    event DealUpdated(uint indexed dealID);

    event Billed(uint indexed dealID, uint indexed paidAmount);

    event DealChangeRequestSet(uint indexed changeRequestID);
    event DealChangeRequestUpdated(uint indexed changeRequestID);

    event WorkerAnnounced(address indexed worker, address indexed master);
    event WorkerConfirmed(address indexed worker, address indexed master);
    event WorkerRemoved(address indexed worker, address indexed master);

    event NumBenchmarksUpdated(uint indexed newNum);
    event NumNetflagsUpdated(uint indexed newNum);

    // VARS

    uint constant MAX_BENCHMARKS_VALUE = 2 ** 63;

    SNM token;

    Blacklist bl;

    OracleUSD oracle;

    ProfileRegistry pr;

    Orders ord;

    Administratum adm;

    uint dealAmount = 0;

    uint requestsAmount = 0;

    // current length of benchmarks
    uint benchmarksQuantity;

    // current length of netflags
    uint netflagsQuantity;

    mapping(uint => Deal) public deals;

    mapping(address => uint[]) dealsID;

    mapping(uint => ChangeRequest) requests;

    mapping(uint => uint[2]) actualRequests;

    // INIT

    constructor(address _token, address _blacklist, address _oracle, address _profileRegistry, address _administratum, address _orders, uint _benchmarksQuantity, uint _netflagsQuantity) public {
        token = SNM(_token);
        bl = Blacklist(_blacklist);
        oracle = OracleUSD(_oracle);
        pr = ProfileRegistry(_profileRegistry);
        adm = Administratum(_administratum);
        ord = Orders(_orders);

        benchmarksQuantity = _benchmarksQuantity;
        netflagsQuantity = _netflagsQuantity;
    }

    // EXTERNAL

    // Order functions

    function PlaceOrder(
        Orders.OrderType _orderType,
        address _counterpartyID,
        uint _duration,
        uint _price,
        bool[] _netflags,
        ProfileRegistry.IdentityLevel _identityLevel,
        address _blacklist,
        bytes32 _tag,
        uint64[] _benchmarks
    ) whenNotPaused public returns (uint) {

        require(_identityLevel >= ProfileRegistry.IdentityLevel.ANONYMOUS);
        require(_netflags.length <= netflagsQuantity);
        require(_benchmarks.length <= benchmarksQuantity);

        for (uint i = 0; i < _benchmarks.length; i++) {
            require(_benchmarks[i] < MAX_BENCHMARKS_VALUE);
        }

        uint lockedSum = 0;

        if (_orderType == Orders.OrderType.ORDER_BID) {
            if (_duration == 0) {
                lockedSum = CalculatePayment(_price, 1 hours);
            } else if (_duration < 1 days) {
                lockedSum = CalculatePayment(_price, _duration);
            } else {
                lockedSum = CalculatePayment(_price, 1 days);
            }
            require(token.transferFrom(msg.sender, this, lockedSum));
        }


        orderId = ord.Write(
            _orderType,
            Orders.OrderStatus.ORDER_ACTIVE,
            msg.sender,
            _counterpartyID,
            _duration,
            _price,
            _netflags,
            _identityLevel,
            _blacklist,
            _tag,
            _benchmarks,
            lockedSum,
            0
        );
        return orderId;
    }

    function CancelOrder(uint orderID) public returns (bool) {
        require(orderID <= ord.GetOrdersAmount());
        Orders.Order memory order = Orders.Order(ord.GetOrderInfo(orderID), ord.GetOrderParams(orderID));
        require(order.OrderParams.orderStatus == OrderStatus.ORDER_ACTIVE);
        require(order.OrderInfo.author == msg.sender);

        require(token.transfer(msg.sender, order.frozenSum));

        ord.Cancel(orderID);

        return true;
    }

    function QuickBuy(uint askID, uint buyoutDuration) public whenNotPaused {
        Orders.Order memory ask = Orders.Order(ord.GetOrderInfo(askID), ord.GetOrderParams(askID));
        require(ask.OrderInfo.orderType == Orders.OrderType.ORDER_ASK);
        require(ask.OrderParams.orderStatus == Orders.OrderStatus.ORDER_ACTIVE);

        require(ask.OrderInfo.duration >= buyoutDuration);
        require(pr.GetProfileLevel(msg.sender) >= ask.OrderInfo.identityLevel);
        require(bl.Check(ask.OrdersInfo.blacklist, msg.sender) == false);
        require(
            bl.Check(msg.sender, adm.GetMaster(ask.author)) == false
            && bl.Check(ask.OrderInfo.author, msg.sender) == false);

        PlaceOrder(
            Orders.OrderType.ORDER_BID,
            adm.GetMaster(ask.author),
            buyoutDuration,
            ask.OrderInfo.price,
            ask.OrderInfo.netflags,
            ProfileRegistry.IdentityLevel.ANONYMOUS,
            address(0),
            bytes32(0),
            ask.OrderInfo.benchmarks);

        OpenDeal(askID, ord.GetOrdersAmount());
    }

    // Deal functions

    function OpenDeal(uint _askID, uint _bidID) whenNotPaused public {
        Orders.Order memory ask = Orders.Order(ord.GetOrderInfo(askID), ord.GetOrderParams(askID));
        Orders.Order memory ask = Orders.Order(ord.GetOrderInfo(bidID), ord.GetOrderParams(bidID));

        require(
            ask.OrderParams.orderStatus == Orders.OrderStatus.ORDER_ACTIVE
            && bid.OrderParams.orderStatus == Orders.OrderStatus.ORDER_ACTIVE);
        require(
            (ask.OrderInfo.counterparty == 0x0 || ask.OrderInfo.counterparty == adm.GetMaster(bid.author))
            && (bid.OrderInfo.counterparty == 0x0 || bid.OrderInfo.counterparty == GetMaster(ask.author)));
        require(ask.OrderInfo.orderType == Orders.OrderType.ORDER_ASK);
        require(bid.OrderInfo.orderType == Orders.OrderType.ORDER_BID);
        require(
            bl.Check(bid.OrderInfo.blacklist, adm.GetMaster(ask.OrderInfo.author)) == false
            && bl.Check(bid.OrderInfo.blacklist, ask.OrderInfo.author) == false
            && bl.Check(bid.OrderInfo.author, adm.GetMaster(ask.author)) == false
            && bl.Check(bid.OrderInfo.author, ask.OrderInfo.author) == false
            && bl.Check(ask.OrderInfo.blacklist, bid.OrderInfo.author) == false
            && bl.Check(adm.GetMaster(ask.OrderInfo.author), bid.OrderInfo.author) == false
            && bl.Check(ask.OrderInfo.author, bid.OrderInfo.author) == false);
        require(ask.OrderInfo.price <= bid.OrderInfo.price);
        require(ask.OrderInfo.duration >= bid.OrderInfo.duration);
        // profile level check
        require(pr.GetProfileLevel(bid.OrderInfo.author) >= ask.OrderInfo.identityLevel);
        require(pr.GetProfileLevel(adm.GetMaster(ask.author)) >= bid.OrderInfo.identityLevel); //bug

        if (ask.OrderInfo.netflags.length < netflagsQuantity) {
            ask.OrderInfo.netflags = ResizeNetflags(ask.netflags);
        }

        if (bid.OrderInfo.netflags.length < netflagsQuantity) {
            bid.OrderInfo.netflags = ResizeNetflags(ask.OrderInfo.netflags);
        }

        for (uint i = 0; i < ask.OrderInfo.netflags.length; i++) {
            // implementation: when bid contains requirement, ask necessary needs to have this
            // if ask have this one - pass
            require(!bid.OrderInfo.netflags[i] || ask.OrderInfo.netflags[i]);
        }

        if (ask.OrderInfo.benchmarks.length < benchmarksQuantity) {
            ask.OrderInfo.benchmarks = ResizeBenchmarks(ask.OrderInfo.benchmarks);
        }

        if (bid.OrderInfo.benchmarks.length < benchmarksQuantity) {
            bid.OrderInfo.benchmarks = ResizeBenchmarks(bid.OrderInfo.benchmarks);
        }

        for (i = 0; i < ask.OrderInfo.benchmarks.length; i++) {
            require(ask.OrderInfo.benchmarks[i] >= bid.OrderInfo.benchmarks[i]);
        }

        dealAmount = dealAmount.add(1);
        address master = adm.GetMaster(ask.author);
        ord.Cancel(_askID);
        ord.Cancel(_bidID);
        //TODO: FIX AFTER DEALS CRUD IMPLEMENTARTION
        orders[_askID].dealID = dealAmount;
        orders[_bidID].dealID = dealAmount;

        emit OrderUpdated(_askID);
        emit OrderUpdated(_bidID);

        uint startTime = block.timestamp;
        uint endTime = 0;
        // `0` - for spot deal

        // if deal is normal
        if (ask.duration != 0) {
            endTime = startTime.add(bid.OrderInfo.duration);
        }
        uint blockedBalance = bid.OrderInfo.frozenSum;
        deals[dealAmount] = Deal(ask.benchmarks, ask.author, bid.author, master, _askID, _bidID, bid.duration, ask.price, startTime, endTime, DealStatus.STATUS_ACCEPTED, blockedBalance, 0, block.timestamp);
        emit DealOpened(dealAmount);
    }

    function CloseDeal(uint dealID, BlacklistPerson blacklisted) public returns (bool){
        require((deals[dealID].status == DealStatus.STATUS_ACCEPTED));
        require(msg.sender == deals[dealID].supplierID || msg.sender == deals[dealID].consumerID || msg.sender == deals[dealID].masterID);

        if (block.timestamp <= deals[dealID].startTime.add(deals[dealID].duration)) {
            // after endTime
            require(deals[dealID].consumerID == msg.sender);
        }
        AddToBlacklist(dealID, blacklisted);
        InternalBill(dealID);
        InternalCloseDeal(dealID);
        RefundRemainingFunds(dealID);
        return true;
    }

    function Bill(uint dealID) public returns (bool){
        InternalBill(dealID);
        ReserveNextPeriodFunds(dealID);
        return true;
    }

    function CreateChangeRequest(uint dealID, uint newPrice, uint newDuration) public returns (uint changeRequestID) {
        require(msg.sender == deals[dealID].consumerID || msg.sender == deals[dealID].masterID || msg.sender == deals[dealID].supplierID);
        require(deals[dealID].status == DealStatus.STATUS_ACCEPTED);

        if (IsSpot(dealID)) {
            require(newDuration == 0);
        }

        requestsAmount = requestsAmount.add(1);

        Orders.OrderType requestType;

        if (msg.sender == deals[dealID].consumerID) {
            requestType = OrderType.ORDER_BID;
        } else {
            requestType = OrderType.ORDER_ASK;
        }

        requests[requestsAmount] = ChangeRequest(dealID, requestType, newPrice, newDuration, RequestStatus.REQUEST_CREATED);
        emit DealChangeRequestSet(requestsAmount);

        if (requestType == Orders.OrderType.ORDER_BID) {
            emit DealChangeRequestUpdated(actualRequests[dealID][1]);
            requests[actualRequests[dealID][1]].status = RequestStatus.REQUEST_CANCELED;
            actualRequests[dealID][1] = requestsAmount;
            ChangeRequest memory matchingRequest = requests[actualRequests[dealID][0]];

            if (newDuration == deals[dealID].duration && newPrice > deals[dealID].price) {
                requests[requestsAmount].status = RequestStatus.REQUEST_ACCEPTED;
                Bill(dealID);
                deals[dealID].price = newPrice;
                actualRequests[dealID][1] = 0;
                emit DealChangeRequestUpdated(requestsAmount);
            } else if (matchingRequest.status == RequestStatus.REQUEST_CREATED && matchingRequest.duration >= newDuration && matchingRequest.price <= newPrice) {
                requests[requestsAmount].status = RequestStatus.REQUEST_ACCEPTED;
                requests[actualRequests[dealID][0]].status = RequestStatus.REQUEST_ACCEPTED;
                emit DealChangeRequestUpdated(actualRequests[dealID][0]);
                actualRequests[dealID][0] = 0;
                actualRequests[dealID][1] = 0;
                Bill(dealID);
                deals[dealID].price = matchingRequest.price;
                deals[dealID].duration = newDuration;
                emit DealChangeRequestUpdated(requestsAmount);
            } else {
                return requestsAmount;
            }

            requests[actualRequests[dealID][1]].status = RequestStatus.REQUEST_CANCELED;
            emit DealChangeRequestUpdated(actualRequests[dealID][1]);
            actualRequests[dealID][1] = requestsAmount;
        }

        if (requestType == Orders.OrderType.ORDER_ASK) {
            emit DealChangeRequestUpdated(actualRequests[dealID][0]);
            requests[actualRequests[dealID][0]].status = RequestStatus.REQUEST_CANCELED;
            actualRequests[dealID][0] = requestsAmount;
            matchingRequest = requests[actualRequests[dealID][1]];

            if (newDuration == deals[dealID].duration && newPrice < deals[dealID].price) {
                requests[requestsAmount].status = RequestStatus.REQUEST_ACCEPTED;
                Bill(dealID);
                deals[dealID].price = newPrice;
                actualRequests[dealID][0] = 0;
                emit DealChangeRequestUpdated(requestsAmount);
            } else if (matchingRequest.status == RequestStatus.REQUEST_CREATED && matchingRequest.duration <= newDuration && matchingRequest.price >= newPrice) {
                requests[requestsAmount].status = RequestStatus.REQUEST_ACCEPTED;
                requests[actualRequests[dealID][1]].status = RequestStatus.REQUEST_ACCEPTED;
                emit DealChangeRequestUpdated(actualRequests[dealID][1]); //bug
                actualRequests[dealID][0] = 0;
                actualRequests[dealID][1] = 0;
                Bill(dealID);
                deals[dealID].price = newPrice;
                deals[dealID].duration = matchingRequest.duration;
                emit DealChangeRequestUpdated(requestsAmount);
            } else {
                return requestsAmount;
            }
        }

        deals[dealID].endTime = deals[dealID].startTime.add(deals[dealID].duration);
        return requestsAmount;
    }

    function CancelChangeRequest(uint changeRequestID) public returns (bool) {
        ChangeRequest memory request = requests[changeRequestID];
        require(msg.sender == deals[request.dealID].supplierID || msg.sender == deals[request.dealID].masterID || msg.sender == deals[request.dealID].consumerID);
        require(request.status != RequestStatus.REQUEST_ACCEPTED);

        if (request.requestType == Orders.OrderType.ORDER_ASK) {
            if (msg.sender == deals[request.dealID].consumerID) {
                requests[changeRequestID].status = RequestStatus.REQUEST_REJECTED;
            } else {
                requests[changeRequestID].status = RequestStatus.REQUEST_CANCELED;
            }
            actualRequests[request.dealID][0] = 0;
            emit DealChangeRequestUpdated(changeRequestID);
        }

        if (request.requestType == Orders.OrderType.ORDER_BID) {
            if (msg.sender == deals[request.dealID].consumerID) {
                requests[changeRequestID].status = RequestStatus.REQUEST_CANCELED;
            } else {
                requests[changeRequestID].status = RequestStatus.REQUEST_REJECTED;
            }
            actualRequests[request.dealID][1] = 0;
            emit DealChangeRequestUpdated(changeRequestID);
        }
        return true;
    }


    // GETTERS

    function GetDealInfo(uint dealID) view public
    returns (
        uint64[] benchmarks,
        address supplierID,
        address consumerID,
        address masterID,
        uint askID,
        uint bidID,
        uint startTime
    ){
        return (
        deals[dealID].benchmarks,
        deals[dealID].supplierID,
        deals[dealID].consumerID,
        deals[dealID].masterID,
        deals[dealID].askID,
        deals[dealID].bidID,
        deals[dealID].startTime

        );
    }

    function GetDealParams(uint dealID) view public
    returns (
        uint duration,
        uint price,
        uint endTime,
        DealStatus status,
        uint blockedBalance,
        uint totalPayout,
        uint lastBillTS
    ){
        return (
        deals[dealID].duration,
        deals[dealID].price,
        deals[dealID].endTime,
        deals[dealID].status,
        deals[dealID].blockedBalance,
        deals[dealID].totalPayout,
        deals[dealID].lastBillTS
        );
    }


    function GetChangeRequestInfo(uint changeRequestID) view public
    returns (
        uint dealID,
        Orders.OrderType requestType,
        uint price,
        uint duration,
        RequestStatus status
    ){
        return (
        requests[changeRequestID].dealID,
        requests[changeRequestID].requestType,
        requests[changeRequestID].price,
        requests[changeRequestID].duration,
        requests[changeRequestID].status
        );
    }

    function GetDealsAmount() public view returns (uint){
        return dealAmount;
    }

    function GetChangeRequestsAmount() public view returns (uint){
        return requestsAmount;
    }

    function GetBenchmarksQuantity() public view returns (uint) {
        return benchmarksQuantity;
    }

    function GetNetflagsQuantity() public view returns (uint) {
        return netflagsQuantity;
    }


    // INTERNAL

    function InternalBill(uint dealID) internal returns (bool){
        require(deals[dealID].status == DealStatus.STATUS_ACCEPTED);
        require(msg.sender == deals[dealID].supplierID || msg.sender == deals[dealID].consumerID || msg.sender == deals[dealID].masterID);
        Deal memory deal = deals[dealID];

        uint paidAmount;

        if (!IsSpot(dealID) && deal.lastBillTS >= deal.endTime) {
            // means we already billed deal after endTime
            return true;
        } else if (!IsSpot(dealID) && block.timestamp > deal.endTime && deal.lastBillTS < deal.endTime) {
            paidAmount = CalculatePayment(deal.price, deal.endTime.sub(deal.lastBillTS));
        } else {
            paidAmount = CalculatePayment(deal.price, block.timestamp.sub(deal.lastBillTS));
        }

        if (paidAmount > deal.blockedBalance) {
            if (token.balanceOf(deal.consumerID) >= paidAmount.sub(deal.blockedBalance)) {
                require(token.transferFrom(deal.consumerID, this, paidAmount.sub(deal.blockedBalance)));
                deals[dealID].blockedBalance = deals[dealID].blockedBalance.add(paidAmount.sub(deal.blockedBalance));
            } else {
                emit Billed(dealID, deals[dealID].blockedBalance);
                InternalCloseDeal(dealID);
                require(token.transfer(deal.masterID, deal.blockedBalance));
                deals[dealID].lastBillTS = block.timestamp;
                deals[dealID].totalPayout = deals[dealID].totalPayout.add(deal.blockedBalance);
                deals[dealID].blockedBalance = 0;
                return true;
            }
        }
        require(token.transfer(deal.masterID, paidAmount));
        deals[dealID].blockedBalance = deals[dealID].blockedBalance.sub(paidAmount);
        deals[dealID].totalPayout = deals[dealID].totalPayout.add(paidAmount);
        deals[dealID].lastBillTS = block.timestamp;
        emit Billed(dealID, paidAmount);
        return true;
    }

    function ReserveNextPeriodFunds(uint dealID) internal returns (bool) {
        uint nextPeriod;
        Deal memory deal = deals[dealID];

        if (IsSpot(dealID)) {
            if (deal.status == DealStatus.STATUS_CLOSED) {
                return true;
            }
            nextPeriod = 1 hours;
        } else {
            if (block.timestamp > deal.endTime) {
                // we don't reserve funds for next period
                return true;
            }
            if (deal.endTime.sub(block.timestamp) < 1 days) {
                nextPeriod = deal.endTime.sub(block.timestamp);
            } else {
                nextPeriod = 1 days;
            }
        }

        if (CalculatePayment(deal.price, nextPeriod) > deals[dealID].blockedBalance) {
            uint nextPeriodSum = CalculatePayment(deal.price, nextPeriod).sub(deals[dealID].blockedBalance);

            if (token.balanceOf(deal.consumerID) >= nextPeriodSum) {
                require(token.transferFrom(deal.consumerID, this, nextPeriodSum));
                deals[dealID].blockedBalance = deals[dealID].blockedBalance.add(nextPeriodSum);
            } else {
                emit Billed(dealID, deals[dealID].blockedBalance);
                InternalCloseDeal(dealID);
                RefundRemainingFunds(dealID);
                return true;
            }
        }
        return true;
    }

    function RefundRemainingFunds(uint dealID) internal returns (bool){
        if (deals[dealID].blockedBalance != 0) {
            token.transfer(deals[dealID].consumerID, deals[dealID].blockedBalance);
            deals[dealID].blockedBalance = 0;
        }
        return true;
    }

    function IsSpot(uint dealID) internal view returns (bool){
        return deals[dealID].duration == 0;
    }

    function CalculatePayment(uint _price, uint _period) internal view returns (uint) {
        uint rate = oracle.getCurrentPrice();
        return rate.mul(_price).mul(_period).div(1e18);
    }

    function AddToBlacklist(uint dealID, BlacklistPerson role) internal {
        // only consumer can blacklist
        require(msg.sender == deals[dealID].consumerID || role == BlacklistPerson.BLACKLIST_NOBODY);
        if (role == BlacklistPerson.BLACKLIST_WORKER) {
            bl.Add(deals[dealID].consumerID, deals[dealID].supplierID);
        } else if (role == BlacklistPerson.BLACKLIST_MASTER) {
            bl.Add(deals[dealID].consumerID, deals[dealID].masterID);
        }
    }

    function InternalCloseDeal(uint dealID) internal {
        if (deals[dealID].status == DealStatus.STATUS_CLOSED) {
            return;
        }
        require((deals[dealID].status == DealStatus.STATUS_ACCEPTED));
        require(msg.sender == deals[dealID].consumerID || msg.sender == deals[dealID].supplierID || msg.sender == deals[dealID].masterID);
        deals[dealID].status = DealStatus.STATUS_CLOSED;
        deals[dealID].endTime = block.timestamp;
        emit DealUpdated(dealID);
    }

    function ResizeBenchmarks(uint64[] _benchmarks) internal view returns (uint64[]) {
        uint64[] memory benchmarks = new uint64[](benchmarksQuantity);
        for (uint i = 0; i < _benchmarks.length; i++) {
            benchmarks[i] = _benchmarks[i];
        }
        return benchmarks;
    }

    function ResizeNetflags(bool[] _netflags) internal view returns (bool[]) {
        bool[] memory netflags = new bool[](netflagsQuantity);
        for (uint i = 0; i < _netflags.length; i++) {
            netflags[i] = _netflags[i];
        }
        return netflags;
    }

    // SETTERS

    function SetProfileRegistryAddress(address _newPR) onlyOwner public returns (bool) {
        pr = ProfileRegistry(_newPR);
        return true;
    }

    function SetBlacklistAddress(address _newBL) onlyOwner public returns (bool) {
        bl = Blacklist(_newBL);
        return true;
    }

    function SetOracleAddress(address _newOracle) onlyOwner public returns (bool) {
        require(OracleUSD(_newOracle).getCurrentPrice() != 0);
        oracle = OracleUSD(_newOracle);
        return true;
    }

    function SetBenchmarksQuantity(uint _newQuantity) onlyOwner public returns (bool) {
        require(_newQuantity > benchmarksQuantity);
        emit NumBenchmarksUpdated(_newQuantity);
        benchmarksQuantity = _newQuantity;
        return true;
    }

    function SetNetflagsQuantity(uint _newQuantity) onlyOwner public returns (bool) {
        require(_newQuantity > netflagsQuantity);
        emit NumNetflagsUpdated(_newQuantity);
        netflagsQuantity = _newQuantity;
        return true;
    }

    function KillMarket() onlyOwner public {
        token.transfer(owner, token.balanceOf(address(this)));
        selfdestruct(owner);
    }
}
