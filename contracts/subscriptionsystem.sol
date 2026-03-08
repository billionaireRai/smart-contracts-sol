// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SubscriptionContract is Ownable(msg.sender) {
    enum PlanType { Standard, Pro, Premium }
    
    struct Plan {
        uint256 cost;
        PlanType Type;
    }

    struct SubscriptionInfo {
        address subscriber;
        Plan plan;
        uint256 expiryTime;
    }

    uint256 public totalSubs;
    mapping(address => SubscriptionInfo) public subscriptions;
    mapping(PlanType => uint256) private planCosts;

    event SubscriptionCreated(address indexed subscriber, PlanType planType);
    event SubscriptionRenewed(address indexed subscriber, PlanType planType);

    constructor() {
        planCosts[PlanType.Standard] = 1 ether;
        planCosts[PlanType.Pro] = 5 ether;
        planCosts[PlanType.Premium] = 10 ether;
    }

    modifier validPlanCost(uint256 _amount) {
        if (_amount != planCosts[PlanType.Standard] &&
            _amount != planCosts[PlanType.Pro] &&
            _amount != planCosts[PlanType.Premium]) {
            revert("Invalid plan cost");
        }
        _;
    }

    function subscriptionProtectedService() public view returns (string memory) {
        if (isAddressSubscribed(msg.sender)) return "Access granted. Enjoy the service!";
        else return "Please subscribe to access this service.";
        
    }

    function getOrUpdateSubscription() public payable validPlanCost(msg.value) {
        PlanType planType;
        if (msg.value == planCosts[PlanType.Standard]) {
            planType = PlanType.Standard;
        } else if (msg.value == planCosts[PlanType.Pro]) {
            planType = PlanType.Pro;
        } else {
            planType = PlanType.Premium;
        }

        if (subscriptions[msg.sender].subscriber == address(0)) {
            // New subscription
            subscriptions[msg.sender] = SubscriptionInfo({
                subscriber: msg.sender,
                plan: Plan({
                    cost: msg.value,
                    Type: planType
                }),
                expiryTime: block.timestamp + 4 weeks
            });
            totalSubs++;
            emit SubscriptionCreated(msg.sender, planType);
        } else {
            // Renew subscription
            subscriptions[msg.sender].plan = Plan({
                cost: msg.value,
                Type: planType
            });
            subscriptions[msg.sender].expiryTime = block.timestamp + 4 weeks;
            emit SubscriptionRenewed(msg.sender, planType);
        }
    }

    function isAddressSubscribed(address _address) public view returns (bool) {
        SubscriptionInfo memory subInfo = subscriptions[_address];
        return (subInfo.subscriber != address(0) && subInfo.expiryTime >= block.timestamp);
    }

    function getPlanCost(PlanType _planType) public view returns (uint256) {
        return planCosts[_planType];
    }
}