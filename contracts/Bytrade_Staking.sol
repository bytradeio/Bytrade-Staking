// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bytrade_Staking {

    address public Token;
    mapping(address => userDeposit[]) public userDeposits;
    uint256 public totalStaked;
    uint256 public totalSent;
    uint256 public stakedInterest;
    uint256 public interestSent;

    // events for staking and unstaking
    event Stake(address userAddress, address tokenAddress, uint256 amount);
    event Unstake(address userAddress, address tokenAddress, uint256 amount);
    
    struct tenures {
        uint64 one_month;
        uint64 three_months;
        uint64 six_months;
        uint64 twelve_months;
        uint64 twenty_four_months;
    }

    struct userDeposit {
        uint256 amount;
        uint256 interestAmount;
        uint256 endTime;
        uint256 depositTime;
    }

    /**
    Interest rates 
    one_month = 1.5 %
    three_months = 6 %
    six_months = 15 %
    twelve_months = 40 %
    twenty_four_months = 120 %
    */

    // used 10000000 Basis Points for decimal calculation
    tenures internal interestRate = tenures({one_month: 15000000, three_months: 60000000, six_months: 150000000, twelve_months: 400000000, twenty_four_months: 1200000000});

    
    constructor(address _tokenAddress){
        Token = _tokenAddress;
    }


    /**
    _tenure  = number of months contract will hold the staked amount
    _amount = number of tokens user will stake
    */

    // staking BT token for getting interest
    function stake(uint256 _tenure, uint256 _amount) payable external {
        require(
            _tenure == 1 || _tenure == 3  || _tenure == 6 || _tenure == 12 || _tenure == 24,
            "Staking: Invalid tenure."
        );
        require(
            _amount >= 100 * 10**18,
             "Stake: minimum deposit required is 100 BTT."
        );


        uint256 contractBalance = IERC20(Token).balanceOf(address(this));
        uint256 initialBalance = 400_000_000 * 10**18; // the initial balance contract hold

        // calculating the interest 
        uint256 _interestAmount =  getInterest(_tenure, _amount);

        // contract should hold enough balance to payback the interest against staked amount
        bool available = (contractBalance != 0 && initialBalance - stakedInterest > _interestAmount);
        require(available == true, "Stake: Contract doesn't hold sufficient balance.");

        // transfering token from "user account" to "staking contract"
        bool success = IERC20(Token).transferFrom(msg.sender, address(this), _amount);
        require(success == true, "Stake: Deposit failed!");


        //storing user's deposit details
        userDeposits[msg.sender].push(
            userDeposit({
                amount: _amount,
                interestAmount: _interestAmount,
                endTime: block.timestamp + _tenure * 2629800, // each month have 2629800 seconds, we are multiplying the seconds with number of months
                depositTime: block.timestamp
            })
        );

        totalStaked += _amount;    
        stakedInterest += _interestAmount;
        emit Stake(msg.sender, Token, _amount);
    }

   

    // unstaking token with interest
    function unstake(uint256 _index) public {
        require(
            userDeposits[msg.sender][_index].amount > 0,
            "Unstake: This deposit is already unstaked."
        ); 

        require(
            userDeposits[msg.sender][_index].endTime < block.timestamp,
            "Unstake: You can't withdraw your funds unless the staking period is not over."
        );

        uint256 _withdrawAmount = userDeposits[msg.sender][_index].amount + userDeposits[msg.sender][_index].interestAmount;
        // returning deposit with interest
        bool success = IERC20(Token).transfer(msg.sender, _withdrawAmount);
        require(success == true, "Unsatke: Withdraw failed!");
        
        totalSent += _withdrawAmount;
        interestSent += userDeposits[msg.sender][_index].interestAmount;
        delete userDeposits[msg.sender][_index];

        emit Unstake(msg.sender, Token, _withdrawAmount);
    }


    // getting the list of user's deposits
    function getUserDeposits(address userAddress)
        external
        view
        returns (userDeposit[] memory)
    {
        return userDeposits[userAddress];
    }

     /**
    _tenure  = number of months contract will hold the staked amount
    _amount = number of tokens user will stake
    */

      // calculating the interest amount
    function getInterest(uint256 _tenure, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        if (_tenure == 1){
           uint256 finalAmount =  getYieldMultiplier (_amount, interestRate.one_month);
           return finalAmount;
        } else if (_tenure == 3){
            uint256 finalAmount =  getYieldMultiplier (_amount, interestRate.three_months);
           return finalAmount;
        } else if (_tenure == 6){
            uint256 finalAmount =  getYieldMultiplier (_amount, interestRate.six_months);
           return finalAmount;
        }else if (_tenure == 12){
            uint256 finalAmount =  getYieldMultiplier (_amount, interestRate.twelve_months);
           return finalAmount;
        }else if (_tenure == 24){
            uint256 finalAmount =  getYieldMultiplier (_amount, interestRate.twenty_four_months);
           return finalAmount;
        } else return 0;
        
    }


     // Calculating interest based on contract halving
    function getYieldMultiplier(uint256 _amount, uint256 _percent)
        internal
        view
        returns (uint256)
    {
        uint256 _halving;
        uint256 decimals = 10 **18;
        uint256 contractBalance = (400_000_000 * decimals) - stakedInterest; // the initial balance contract hold minus interst dedicated to other deposits

        if (contractBalance > 200_000_000 * decimals){
            _halving = 1;
        } else if (contractBalance <= 200_000_000 * decimals && contractBalance > 100_000_000 * decimals){
            _halving = 2;
        } else if (contractBalance <= 100_000_000 * decimals && contractBalance > 50_000_000 * decimals){
            _halving = 4;
        } else if (contractBalance <= 50_000_000 * decimals && contractBalance > 25_000_000 * decimals){
            _halving = 8;
        } else if (contractBalance <= 25_000_000 * decimals && contractBalance > 12_500_000 * decimals){
            _halving = 16;
        } else if (contractBalance <= 12_500_000 * decimals && contractBalance > 6_250_000 * decimals){
            _halving = 32;
        } else {
            return 0;
        }

        uint256 percentage = _percent / _halving;
        uint256 temp = _amount * percentage;
        uint256 finalAmont = temp/ 100_0000000; // removing 10000000 Basis Points
        return finalAmont;
    }


}
