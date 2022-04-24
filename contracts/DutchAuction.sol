// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";

contract DutchAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public offerPriceDecrement;
    uint public dutchEndingPrice = 0.08 ether;
    uint public dutchPriceAdditional; 
    uint public dutchStartTime; 
    uint public dutchDuration; 
    uint public dutchEndTime; 
    bool public dutchAuctionStarted; 

    modifier dutchAuction {
        require(dutchAuctionStarted && block.timestamp >= dutchStartTime, "Dutch auction has not started yet!");
        _;
    }
    function setDutchAuctionStartStatus(bool bool_) public onlyOwner {
        dutchAuctionStarted = bool_;
    }

    // Dutch Action Initialize
    function setDutchAuction(uint dutchPriceAdditional_, uint dutchStartTime_, uint dutchDuration_) public onlyOwner {
        dutchPriceAdditional = dutchPriceAdditional_; // set the additional price of dutch to deduct
        dutchStartTime = dutchStartTime_; // record the current start time as UNIX timestamp
        dutchDuration = dutchDuration_; // record the duration of the dutch in order to deduct
        dutchEndTime = dutchStartTime.add(dutchDuration); // record for safekeeping the ending time
    }

    // Dutch Auction Functions
    function getTimeElapsed() public view returns (uint) {
        return dutchStartTime > 0 ? dutchStartTime.add(dutchDuration) >= block.timestamp ? block.timestamp.sub(dutchStartTime) : dutchDuration : 0; // this value will end at dutchDuration as maximum.
    }
    function getTimeRemaining() public view returns (uint) {
        return dutchDuration.sub(getTimeElapsed());
    }

    function getAdditionalPrice() public view returns (uint) {
        return dutchDuration.sub(getTimeElapsed()).mul(dutchPriceAdditional).div(dutchDuration); // magic equation to calculate additional price on top of ending price
    }
    function getCurrentDutchPrice() public view returns (uint) {
        return dutchEndingPrice.add(getAdditionalPrice());
    }


    // constructor
    constructor(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _offerPriceDecrement)
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        offerPriceDecrement = _offerPriceDecrement;

        function mintDutchAuctionMany(uint amount_) public payable onlySender dutchAuction {
        require(tokensReservedForDutchAuction >= tokensMintedForDutchAuction + amount_, "No more tokens for Dutch Auction!");
        require(maxTokens >= totalSupply() + amount_, "No more tokens remaining!");
        require(5 >= amount_, "You can only mint up to 5 per transaction!");
        require(msg.value >= getCurrentDutchPrice() * amount_, "Invalid value sent!");

        tokensMintedForDutchAuction += amount_; // increase tokens minted for dutch auction tracker

        for (uint i = 0; i < amount_; i++) {

            uint _mintId = totalSupply();
            uint _currentPrice = getCurrentDutchPrice();
            _mint(msg.sender, _mintId);
            
            emit MintDutchAuction(msg.sender, _currentPrice, _mintId);
        }
    }

    function mintDutchAuction() public payable onlySender dutchAuction {
        require(tokensReservedForDutchAuction > tokensMintedForDutchAuction, "No more tokens for Dutch Auction!");
        require(maxTokens > totalSupply(), "No more tokens remaining!");
        require(msg.value >= getCurrentDutchPrice(), "Invalid value sent!");

        tokensMintedForDutchAuction++; // increase tokens minted for dutch auction tracker

        uint _mintId = totalSupply();
        uint _currentPrice = getCurrentDutchPrice();
        _mint(msg.sender, _mintId);
        
        emit MintDutchAuction(msg.sender, _currentPrice, _mintId);
    }
    }


    function bid() public payable{
        uint public rolloverSalePrice;
    uint public rolloverSaleStartTime; 
    bool public rolloverSaleStarted;
    uint public rolloverSaleTokensMinted;

    modifier rolloverSale {
        require(rolloverSaleStarted && block.timestamp >= rolloverSaleStartTime, "Rollover sale has not started yet!");
        _;
    }
    // Rollover Sale Functions
    function setRolloverSalePrice(uint price_) public onlyOwner {
        rolloverSalePrice = price_;
    }
    function setRolloverSaleStatus(uint rolloverSaleStartTime_, bool bool_) public onlyOwner {
        require(rolloverSalePrice != 0, "You have not set a rollover sale price!");
        rolloverSaleStartTime = rolloverSaleStartTime_;
        rolloverSaleStarted = bool_;
    }
    function mintRolloverSaleMany(uint amount_) public payable onlySender rolloverSale {
        require(maxTokens >= totalSupply() + amount_, "No remaining tokens left!");
        require(5 >= amount_, "You can only mint up to 5 per transaction!");
        require(msg.value == rolloverSalePrice * amount_, "Invalid value sent!");

        rolloverSaleTokensMinted += amount_; // add to tracker of public sale tokens minted

        for (uint i = 0; i < amount_; i++) {
            uint _mintId = totalSupply();
            _mint(msg.sender, _mintId);

            emit MintRolloverSale(msg.sender, _mintId);
        }
    }
    function mintRolloverSale() public payable onlySender rolloverSale {
        require(maxTokens > totalSupply(), "No remaining tokens left!");
        require(msg.value == rolloverSalePrice, "Invalid value sent!");

        rolloverSaleTokensMinted++; // add to tracker of public sale tokens minted

        uint _mintId = totalSupply();
        _mint(msg.sender, _mintId);

        emit MintRolloverSale(msg.sender, _mintId);
    }
    }

}
