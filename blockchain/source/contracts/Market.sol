pragma solidity ^0.4.23;


import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./SNM.sol";
import "./Blacklist.sol";
import "./OracleUSD.sol";
import "./ProfileRegistry.sol";
import "./Administratum.sol";
import "./Orders.sol";
import "./Deals.sol";


contract Market is Ownable, Pausable {

    using SafeMath for uint256;

    // DECLARATIONS


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


    struct ChangeRequest {
        uint dealID;
        Orders.OrderType requestType;
        uint price;
        uint duration;
        RequestStatus status;
    }

    // EVENTS
    event OrderPlaced(uint indexed orderID);
    event OrderUpdated(uint indexed orderID);

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

    Deals dl;

    uint requestsAmount = 0;

    // current length of benchmarks
    uint benchmarksQuantity;

    // current length of netflags
    uint netflagsQuantity;

    mapping(uint => ChangeRequest) requests;

    mapping(uint => uint[2]) actualRequests;

    // INIT

    constructor(address _token,
        address _blacklist,
        address _oracle,
        address _profileRegistry,
        address _administratum,
        address _orders,
        address _deals,
        uint _benchmarksQuantity,
        uint _netflagsQuantity) public {
        token = SNM(_token);
        bl = Blacklist(_blacklist);
        oracle = OracleUSD(_oracle);
        pr = ProfileRegistry(_profileRegistry);
        adm = Administratum(_administratum);
        ord = Orders(_orders);
        dl = Deals(_deals);

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


        uint orderID = ord.Write(
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

        emit OrderPlaced(orderID);

        return orderID;
    }

    function CancelOrder(uint orderID) public returns (bool) {
        require(orderID <= ord.GetOrdersAmount());

        (, address author, , , , , , , , , uint frozenSum ) = ord.GetOrderInfo(orderID);

        (Orders.OrderStatus orderStatus, ) = ord.GetOrderParams(orderID);


        require(orderStatus == Orders.OrderStatus.ORDER_ACTIVE);
        require(author == msg.sender || adm.GetMaster(author) == msg.sender);

        require(token.transfer(msg.sender, frozenSum));

        ord.SetOrderStatus(orderID, Orders.OrderStatus.ORDER_INACTIVE);

        emit OrderUpdated(orderID);

        return true;
    }

    function QuickBuy(uint askID, uint buyoutDuration) public whenNotPaused {
        (
        Orders.OrderType orderType,
        address author,
        address counterparty,
        uint duration,
        uint price,
        bool[] memory netflags,
        ProfileRegistry.IdentityLevel identityLevel,
        address blacklist,
        bytes32 tag,
        uint64[] memory benchmarks,
        uint frozenSum) = ord.GetOrderInfo(askID);

        Orders.OrderInfo memory info = Orders.OrderInfo(orderType,
            author,
            counterparty,
            duration,
            price,
            netflags,
            identityLevel,
            blacklist,
            tag,
            benchmarks,
            frozenSum);

        (
        Orders.OrderStatus orderStatus,
        uint dealID) = ord.GetOrderParams(askID);

        Orders.OrderParams memory params = Orders.OrderParams(orderStatus, dealID);

        Orders.Order memory ask = Orders.Order(info, params);

        require(ask.info.orderType == Orders.OrderType.ORDER_ASK);
        require(ask.params.orderStatus == Orders.OrderStatus.ORDER_ACTIVE);

        require(ask.info.duration >= buyoutDuration);
        require(pr.GetProfileLevel(msg.sender) >= ask.info.identityLevel);
        require(bl.Check(ask.info.blacklist, msg.sender) == false);
        require(
            bl.Check(msg.sender, adm.GetMaster(ask.info.author)) == false
            && bl.Check(ask.info.author, msg.sender) == false);

        PlaceOrder(
            Orders.OrderType.ORDER_BID,
            adm.GetMaster(ask.info.author),
            buyoutDuration,
            ask.info.price,
            ask.info.netflags,
            ProfileRegistry.IdentityLevel.ANONYMOUS,
            address(0),
            bytes32(0),
            ask.info.benchmarks);

        OpenDeal(askID, ord.GetOrdersAmount());
    }

    // Deal functions

    function OpenDeal(uint _askID, uint _bidID) whenNotPaused public {
        (
        Orders.OrderType orderType,
        address author,
        address counterparty,
        uint duration,
        uint price,
        bool[] memory netflags,
        ProfileRegistry.IdentityLevel identityLevel,
        address blacklist,
        bytes32 tag,
        uint64[] memory benchmarks,
        uint frozenSum) = ord.GetOrderInfo(_askID);

        Orders.OrderInfo memory info = Orders.OrderInfo(orderType,
            author,
            counterparty,
            duration,
            price,
            netflags,
            identityLevel,
            blacklist,
            tag,
            benchmarks,
            frozenSum);

        (Orders.OrderStatus orderStatus, uint dealID) = ord.GetOrderParams(_askID);

        Orders.OrderParams memory params = Orders.OrderParams(orderStatus, dealID);

        Orders.Order memory ask = Orders.Order(info, params);

        (
        orderType,
        author,
        counterparty,
        duration,
        price,
        netflags,
        identityLevel,
        blacklist,
        tag,
        benchmarks,
        frozenSum) = ord.GetOrderInfo(_bidID);

        info = Orders.OrderInfo(orderType,
            author,
            counterparty,
            duration,
            price,
            netflags,
            identityLevel,
            blacklist,
            tag,
            benchmarks,
            frozenSum);

        (orderStatus, dealID) = ord.GetOrderParams(_bidID);

        params = Orders.OrderParams(orderStatus, dealID);

        Orders.Order memory bid = Orders.Order(info, params);

        require(
            ask.params.orderStatus == Orders.OrderStatus.ORDER_ACTIVE
            && bid.params.orderStatus == Orders.OrderStatus.ORDER_ACTIVE);
        require(
            (ask.info.counterparty == 0x0 || ask.info.counterparty == adm.GetMaster(bid.info.author))
            && (bid.info.counterparty == 0x0 || bid.info.counterparty == adm.GetMaster(ask.info.author)));
        require(ask.info.orderType == Orders.OrderType.ORDER_ASK);
        require(bid.info.orderType == Orders.OrderType.ORDER_BID);
        require(
            bl.Check(bid.info.blacklist, adm.GetMaster(ask.info.author)) == false
            && bl.Check(bid.info.blacklist, ask.info.author) == false
            && bl.Check(bid.info.author, adm.GetMaster(ask.info.author)) == false
            && bl.Check(bid.info.author, ask.info.author) == false
            && bl.Check(ask.info.blacklist, bid.info.author) == false
            && bl.Check(adm.GetMaster(ask.info.author), bid.info.author) == false
            && bl.Check(ask.info.author, bid.info.author) == false);
        require(ask.info.price <= bid.info.price);
        require(ask.info.duration >= bid.info.duration);
        // profile level check
        require(pr.GetProfileLevel(bid.info.author) >= ask.info.identityLevel);
        require(pr.GetProfileLevel(adm.GetMaster(ask.info.author)) >= bid.info.identityLevel); //bug

        if (ask.info.netflags.length < netflagsQuantity) {
            ask.info.netflags = ResizeNetflags(ask.info.netflags);
        }

        if (bid.info.netflags.length < netflagsQuantity) {
            bid.info.netflags = ResizeNetflags(ask.info.netflags);
        }

        for (uint i = 0; i < ask.info.netflags.length; i++) {
            // implementation: when bid contains requirement, ask necessary needs to have this
            // if ask have this one - pass
            require(!bid.info.netflags[i] || ask.info.netflags[i]);
        }

        if (ask.info.benchmarks.length < benchmarksQuantity) {
            ask.info.benchmarks = ResizeBenchmarks(ask.info.benchmarks);
        }

        if (bid.info.benchmarks.length < benchmarksQuantity) {
            bid.info.benchmarks = ResizeBenchmarks(bid.info.benchmarks);
        }

        for (i = 0; i < ask.info.benchmarks.length; i++) {
            require(ask.info.benchmarks[i] >= bid.info.benchmarks[i]);
        }

        address master = adm.GetMaster(ask.info.author);
        ord.SetOrderStatus(_askID, Orders.OrderStatus.ORDER_INACTIVE);
        ord.SetOrderStatus(_bidID, Orders.OrderStatus.ORDER_INACTIVE);
        //TODO: FIX AFTER DEALS CRUD IMPLEMENTARTION

        emit OrderUpdated(_askID);
        emit OrderUpdated(_bidID);

        uint startTime = block.timestamp;
        uint endTime = 0;
        // `0` - for spot deal

        // if deal is normal
        if (ask.info.duration != 0) {
            endTime = startTime.add(bid.info.duration);
        }
        uint blockedBalance = bid.info.frozenSum;
        dealID = dl.Write(ask.info.benchmarks,
            ask.info.author,
            bid.info.author,
            master,
            _askID,
            _bidID,
            bid.info.duration,
            ask.info.price,
            startTime,
            endTime,
            Deals.DealStatus.STATUS_ACCEPTED,
            blockedBalance,
            0,
            block.timestamp);

        emit DealOpened(dealID);

        ord.SetOrderDealID(_askID, dealID);
        ord.SetOrderDealID(_bidID, dealID);
    }

    function CloseDeal(uint dealID, BlacklistPerson blacklisted) public returns (bool) {
        (
        uint64[] memory benchmarks,
        address supplierID,
        address consumerID,
        address masterID,
        uint askID,
        uint bidID,
        uint startTime) = dl.GetDealInfo(dealID);

        Deals.DealInfo memory info = Deals.DealInfo(benchmarks,
            supplierID,
            consumerID,
            masterID,
            askID,
            bidID,
            startTime);

        (
        uint duration,
        uint price,
        uint endTime,
        Deals.DealStatus status,
        uint blockedBalance,
        uint totalPayout,
        uint lastBillTS) = dl.GetDealParams(dealID);

        Deals.DealParams memory params = Deals.DealParams(duration,
            price,
            endTime,
            status,
            blockedBalance,
            totalPayout,
            lastBillTS);

        Deals.Deal memory deal = Deals.Deal(info, params);

        require((deal.params.status == Deals.DealStatus.STATUS_ACCEPTED));
        require(msg.sender == deal.info.supplierID
            || msg.sender == deal.info.consumerID
            || msg.sender == deal.info.masterID);

        if (block.timestamp <= deal.info.startTime.add(deal.params.duration)) {
            // after endTime
            require(deal.info.consumerID == msg.sender);
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

    /* function CreateChangeRequest(uint dealID, uint newPrice, uint newDuration) public returns (uint changeRequestID) {
        Deals.Deal memory deal = Deals.Deal(dl.GetDealInfo(dealID), dl.GetDealParams(dealID));
        require(msg.sender == deal.info.consumerID
            || msg.sender == deal.info.masterID
            || msg.sender == deal.info.supplierID);
        require(deal.params.status == Deals.DealStatus.STATUS_ACCEPTED);

        if (deal.params.duration == 0) {
            require(newDuration == 0);
        }

        requestsAmount = requestsAmount.add(1);

        Orders.OrderType requestType;

        if (msg.sender == deal.info.consumerID) {
            requestType = Orders.OderType.ORDER_BID;
        } else {
            requestType = Orders.OrderType.ORDER_ASK;
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
                deal.params.price = newPrice;
                actualRequests[dealID][1] = 0;
                emit DealChangeRequestUpdated(requestsAmount);
            } else if (matchingRequest.status == RequestStatus.REQUEST_CREATED && matchingRequest.duration >= newDuration && matchingRequest.price <= newPrice) {
                requests[requestsAmount].status = RequestStatus.REQUEST_ACCEPTED;
                requests[actualRequests[dealID][0]].status = RequestStatus.REQUEST_ACCEPTED;
                emit DealChangeRequestUpdated(actualRequests[dealID][0]);
                actualRequests[dealID][0] = 0;
                actualRequests[dealID][1] = 0;
                Bill(dealID);
                !!!!!!
                deal.params.price = matchingRequest.price;
                deal.params.duration = newDuration;
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
    } */


    // GETTERS


    function GetChangeRequestInfo(uint changeRequestID) view public
    returns (
        uint dealID,
        Orders.OrderType requestType,
        uint price,
        uint duration,
        RequestStatus status
    ) {
        return (
        requests[changeRequestID].dealID,
        requests[changeRequestID].requestType,
        requests[changeRequestID].price,
        requests[changeRequestID].duration,
        requests[changeRequestID].status
        );
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
        (
        uint64[] memory benchmarks,
        address supplierID,
        address consumerID,
        address masterID,
        uint askID,
        uint bidID,
        uint startTime) = dl.GetDealInfo(dealID);

        Deals.DealInfo memory info = Deals.DealInfo(benchmarks,
            supplierID,
            consumerID,
            masterID,
            askID,
            bidID,
            startTime);

        (
        uint duration,
        uint price,
        uint endTime,
        Deals.DealStatus status,
        uint blockedBalance,
        uint totalPayout,
        uint lastBillTS) = dl.GetDealParams(dealID);

        Deals.DealParams memory params = Deals.DealParams(duration,
            price,
            endTime,
            status,
            blockedBalance,
            totalPayout,
            lastBillTS);

        Deals.Deal memory deal = Deals.Deal(info, params);

        require(deal.params.status == Deals.DealStatus.STATUS_ACCEPTED);
        require(msg.sender == deal.info.supplierID
            || msg.sender == deal.info.consumerID
            || msg.sender == deal.info.masterID);
        uint paidAmount;

        if (deal.params.duration != 0 && deal.params.lastBillTS >= deal.params.endTime) {
            // means we already billed deal after endTime
            return true;
        } else if (deal.params.duration != 0
            && block.timestamp > deal.params.endTime
            && deal.params.lastBillTS < deal.params.endTime) {
            paidAmount = CalculatePayment(deal.params.price, deal.params.endTime.sub(deal.params.lastBillTS));
        } else {
            paidAmount = CalculatePayment(deal.params.price, block.timestamp.sub(deal.params.lastBillTS));
        }

        if (paidAmount > deal.params.blockedBalance) {
            if (token.balanceOf(deal.info.consumerID) >= paidAmount.sub(deal.params.blockedBalance)) {
                require(token.transferFrom(deal.info.consumerID, this, paidAmount.sub(deal.params.blockedBalance)));
                dl.SetDealBlockedBalance(dealID, deal.params.blockedBalance.add(paidAmount.sub(deal.params.blockedBalance)));
            } else {
                emit Billed(dealID, deal.params.blockedBalance);
                InternalCloseDeal(dealID);
                require(token.transfer(deal.info.masterID, deal.params.blockedBalance));
                dl.SetDealBlockedBalance(dealID, 0);
                dl.SetDealTotalPayout(dealID, deal.params.totalPayout.add(deal.params.blockedBalance));
                dl.SetDealEndTime(dealID, block.timestamp);
                return true;
            }
        }
        // update deal state after all
        (
        duration,
        price,
        endTime,
        status,
        blockedBalance,
        totalPayout,
        lastBillTS) = dl.GetDealParams(dealID);

        params = Deals.DealParams(duration,
            price,
            endTime,
            status,
            blockedBalance,
            totalPayout,
            lastBillTS);

        deal = Deals.Deal(info, params);

        require(token.transfer(deal.info.masterID, paidAmount));
        dl.SetDealBlockedBalance(dealID, deal.params.blockedBalance.sub(paidAmount));
        dl.SetDealTotalPayout(dealID, deal.params.totalPayout.add(paidAmount));
        dl.SetDealLastBillTS(dealID, block.timestamp);
        return true;
    }

    function ReserveNextPeriodFunds(uint dealID) internal returns (bool) {
        uint nextPeriod;
        ( , address supplierID, address consumerID , , , , ) = dl.GetDealInfo(dealID);

        (uint duration, uint price, uint endTime, Deals.DealStatus status, uint blockedBalance, , ) = dl.GetDealParams(dealID);

        if (duration == 0) {
            if (status == Deals.DealStatus.STATUS_CLOSED) {
                return true;
            }
            nextPeriod = 1 hours;
        } else {
            if (block.timestamp > endTime) {
                // we don't reserve funds for next period
                return true;
            }
            if (endTime.sub(block.timestamp) < 1 days) {
                nextPeriod = endTime.sub(block.timestamp);
            } else {
                nextPeriod = 1 days;
            }
        }

        if (CalculatePayment(price, nextPeriod) > blockedBalance) {
            uint nextPeriodSum = CalculatePayment(price, nextPeriod).sub(blockedBalance);

            if (token.balanceOf(consumerID) >= nextPeriodSum) {
                require(token.transferFrom(consumerID, this, nextPeriodSum));
                dl.SetDealBlockedBalance(dealID, blockedBalance.add(nextPeriodSum));
            } else {
              // ?????
                emit Billed(dealID, blockedBalance);
                InternalCloseDeal(dealID);
                RefundRemainingFunds(dealID);
                return true;
            }
        }
        return true;
    }

    function RefundRemainingFunds(uint dealID) internal returns (bool) {
      ( , , address consumerID , , , , ) = dl.GetDealInfo(dealID);

      (, , , , uint blockedBalance, , ) = dl.GetDealParams(dealID);

        if (blockedBalance != 0) {
            token.transfer(consumerID, blockedBalance);
            dl.SetDealBlockedBalance(dealID, 0);
        }
        return true;
    }

    //legacy
    /* function IsSpot(uint dealID) internal view returns (bool){
        return deals[dealID].duration == 0;
    } */

    function CalculatePayment(uint _price, uint _period) internal view returns (uint) {
        uint rate = oracle.getCurrentPrice();
        return rate.mul(_price).mul(_period).div(1e18);
    }

    function AddToBlacklist(uint dealID, BlacklistPerson role) internal {
        (, address supplierID, address consumerID, address masterID, , , ) = dl.GetDealInfo(dealID);

        // only consumer can blacklist
        require(msg.sender == consumerID || role == BlacklistPerson.BLACKLIST_NOBODY);
        if (role == BlacklistPerson.BLACKLIST_WORKER) {
            bl.Add(consumerID, supplierID);
        } else if (role == BlacklistPerson.BLACKLIST_MASTER) {
            bl.Add(consumerID, masterID);
        }
    }

    function InternalCloseDeal(uint dealID) internal {
        ( , address supplierID, address consumerID, address masterID, , , ) = dl.GetDealInfo(dealID);

        ( , , , Deals.DealStatus status, , , ) = dl.GetDealParams(dealID);

        if (status == Deals.DealStatus.STATUS_CLOSED) {
            return;
        }
        require((status == Deals.DealStatus.STATUS_ACCEPTED));
        require(msg.sender == consumerID || msg.sender == supplierID || msg.sender == masterID);
        dl.SetDealStatus(dealID, Deals.DealStatus.STATUS_CLOSED);
        dl.SetDealEndTime(dealID, block.timestamp);
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

    function SetDealsAddress(address _newDeals) public onlyOwner returns (bool) {
        dl = Deals(_newDeals);
        return true;
    }

    function SetOrdersAddress(address _newOrders) public onlyOwner returns (bool) {
        ord = Orders(_newOrders);
        return  true;
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
