pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Deals is Ownable {
    //events

    //enums
    enum DealStatus {
        STATUS_UNKNOWN,
        STATUS_ACCEPTED,
        STATUS_CLOSED
    }
    //data

    struct Deal {
        DealInfo info;
        DealParams params;

    }

    struct DealInfo {
        uint64[] benchmarks;
        address supplierID;
        address consumerID;
        address masterID;
        uint askID;
        uint bidID;
        uint startTime;
    }

    struct DealParams {
        uint duration;
        uint price; //usd * 10^-18
        uint endTime;
        DealStatus status;
        uint blockedBalance;
        uint totalPayout;
        uint lastBillTS;
    }

    mapping(uint => Deal) public deals;

    mapping(address => uint[]) dealsID;

    uint dealsAmount = 0;

    //Constructor
    constructor(address _market) public {
        owner = _market;
    }

    function Write(
        uint64[] _benchmarks,
        address _supplierID,
        address _consumerID,
        address _masterID,
        uint _askID,
        uint _bidID,
        uint _duration,
        uint _price,
        uint _startTime,
        uint _endTime,
        DealStatus _status,
        uint _blockedBalance,
        uint _totalPayout,
        uint _lastBillTS) public onlyOwner returns(uint) {

        dealsAmount += 1;

        //DealInfo memory info = DealInfo(_benchmarks, _supplierID, _consumerID, _masterID, _askID, _bidID, __bidID);
        //StoreA(_benchmarks, _supplierID, _consumerID, _masterID, _askID, _bidID, _startTime);
        //DealParams memory params = DealParams(_duration, _price, _endTime, _status, _blockedBalance, _totalPayout, _lastBillTS);
        //StoreB(_duration, _price, _endTime, _status, _blockedBalance, _totalPayout, _lastBillTS);



        deals[dealsAmount].info.benchmarks = _benchmarks;
        deals[dealsAmount].info.supplierID = _supplierID;
        deals[dealsAmount].info.consumerID = _consumerID;
        deals[dealsAmount].info.masterID = _masterID;
        deals[dealsAmount].info.askID = _askID;
        deals[dealsAmount].info.bidID = _bidID;
        deals[dealsAmount].info.startTime = _startTime;
        deals[dealsAmount].params.duration = _duration;
        deals[dealsAmount].params.price = _price;
        deals[dealsAmount].params.endTime = _endTime;
        deals[dealsAmount].params.status = _status;
        deals[dealsAmount].params.blockedBalance = _blockedBalance;
        deals[dealsAmount].params.totalPayout = _totalPayout;
        deals[dealsAmount].params.lastBillTS = _lastBillTS;


        return dealsAmount;
    }

    /* function StoreA(
        uint64[] _benchmarks,
        address _supplierID,
        address _consumerID,
        address _masterID,
        uint _askID,
        uint _bidID,
        uint _startTime
      ) internal {
          deals[dealsAmount] = Deal(DealInfo(_benchmarks, _supplierID, _consumerID, _masterID, _askID, _bidID, _startTime),)
      }

      function StoreA(
        uint _duration,
        uint _price,,
        uint _endTime,
        DealStatus _status,
        uint _blockedBalance,
        uint _totalPayout,
        uint _lastBillTS
        ) interna; {
            deals[dealsAmount] = Deal(,DealParams(_duration, _price, _endTime, _status, _blockedBalance, _totalPayout, _lastBillTS));


        } */



    function Close(uint dealID) public onlyOwner {
        require(dealID >= dealsAmount);
        deals[dealID].params.status = DealStatus.STATUS_CLOSED;
        deals[dealID].params.endTime = block.timestamp;
    }

    function Bill(uint dealID, uint _balance, uint _totalPayout, uint _billTS) public onlyOwner {
        require(dealID >= dealsAmount);
        deals[dealID].params.blockedBalance = _balance;
        deals[dealID].params.lastBillTS = _billTS;
        deals[dealID].params.totalPayout = _totalPayout;
    }

    function SetDealStatus(uint dealID, DealStatus _status) public onlyOwner {
        deals[dealID].params.status = _status;
    }

    function SetDealEndTime(uint dealID, uint _endTime) public onlyOwner {
        deals[dealID].params.endTime = _endTime;
    }

    function SetDealBlockedBalance(uint dealID, uint _blockedBalance) public onlyOwner {
        deals[dealID].params.blockedBalance = _blockedBalance;
    }

    function SetDealLastBillTS(uint dealID, uint _lastBillTS) public onlyOwner {
        deals[dealID].params.lastBillTS = _lastBillTS;
    }

    function SetDealTotalPayout(uint dealID, uint _totalPayout) public onlyOwner {
        deals[dealID].params.totalPayout = _totalPayout;
    }

    function SetDealPrice(uint dealID, uint _price) public onlyOwner {
        deals[dealID].params.price = _price;
    }
    function SetDealDuration(uint dealID, uint _duration) public onlyOwner {
        deals[dealID].params.duration = _duration;
    }


    //getters

    function GetDealInfo(uint dealID) public view
    returns (
        uint64[] benchmarks,
        address supplierID,
        address consumerID,
        address masterID,
        uint askID,
        uint bidID,
        uint startTime
    ) {
        DealInfo memory info = deals[dealID].info;
        return (
        info.benchmarks,
        info.supplierID,
        info.consumerID,
        info.masterID,
        info.askID,
        info.bidID,
        info.startTime
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
    ) {
        DealParams memory params = deals[dealID].params;
        return (
        params.duration,
        params.price,
        params.endTime,
        params.status,
        params.blockedBalance,
        params.totalPayout,
        params.lastBillTS
        );
    }

}
