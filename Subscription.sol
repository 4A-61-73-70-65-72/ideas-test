// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SubscriptionContract {
    address public contractOwner;
    address public serviceWallet;
    address public subscriber;
    uint256 public withdrawalAmount;
    uint256 public withdrawalInterval;
    uint256 public lastWithdrawalTimestamp;
    bool public isSubscriptionActive;
    IERC20 public tokenContract;

    event SubscriptionStarted(address indexed subscriber, address indexed serviceWallet, uint256 withdrawalAmount, uint256 withdrawalInterval);
    event SubscriptionEnded(address indexed subscriber, address indexed serviceWallet);
    event Withdrawal(address indexed subscriber, address indexed serviceWallet, uint256 amount, uint256 timestamp);

    constructor(
        address _serviceWallet,
        uint256 _withdrawalAmount,
        uint256 _withdrawalInterval,
        address _tokenContract
    ) {
        contractOwner = msg.sender;
        serviceWallet = _serviceWallet;
        withdrawalAmount = _withdrawalAmount;
        withdrawalInterval = _withdrawalInterval;
        tokenContract = IERC20(_tokenContract);
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function");
        _;
    }

    modifier onlySubscriber() {
        require(msg.sender == subscriber, "Only the subscriber can call this function");
        _;
    }

    function startSubscription() external {
        require(subscriber == address(0), "Subscription already started");
        subscriber = msg.sender;
        lastWithdrawalTimestamp = block.timestamp;
        isSubscriptionActive = true;
        emit SubscriptionStarted(subscriber, serviceWallet, withdrawalAmount, withdrawalInterval);
    }

    function endSubscription() external onlySubscriber {
        isSubscriptionActive = false;
        subscriber = address(0);
        emit SubscriptionEnded(subscriber, serviceWallet);
    }

    function withdraw() external onlySubscriber {
        require(isSubscriptionActive, "Subscription is not active");
        require(block.timestamp >= lastWithdrawalTimestamp + withdrawalInterval, "Withdrawal interval has not elapsed");

        uint256 availableBalance = tokenContract.balanceOf(address(this));
        require(availableBalance >= withdrawalAmount, "Insufficient contract balance");

        lastWithdrawalTimestamp = block.timestamp;
        tokenContract.transfer(serviceWallet, withdrawalAmount);
        emit Withdrawal(subscriber, serviceWallet, withdrawalAmount, lastWithdrawalTimestamp);
    }

    function changeServiceWallet(address _newServiceWallet) external onlyContractOwner {
        require(_newServiceWallet != address(0), "Invalid service wallet address");
        serviceWallet = _newServiceWallet;
    }

    function changeWithdrawalAmount(uint256 _newWithdrawalAmount) external onlyContractOwner {
        withdrawalAmount = _newWithdrawalAmount;
    }

    function changeWithdrawalInterval(uint256 _newWithdrawalInterval) external onlyContractOwner {
        withdrawalInterval = _newWithdrawalInterval;
    }

    function changeTokenContract(address _newTokenContract) external onlyContractOwner {
        tokenContract = IERC20(_newTokenContract);
    }
}
