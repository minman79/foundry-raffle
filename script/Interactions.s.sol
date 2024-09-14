// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256 subId, address vrfcoordinator) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subbId,) = createSubscription(vrfCoordinator);
        return (subbId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256 subId, address vrfcoordinator) {
        console.log("Creating subscription on chain Id: ", block.chainid);
        vm.startBroadcast();
        uint256 subbId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription(); // running this creates a Mock chainlink subscription
        vm.stopBroadcast();

        console.log("Your subscription Id is: ", subbId);
        console.log("Please update the subscription Id in your HelperConfig.s.sol");
        return (subbId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}
