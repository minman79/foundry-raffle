// SPDX-License-Identifier: MIT

// unit - Basic Tests
// integrations - Testing how all our contracts interact with one another
// forked - Copy of testnets and locally install them
// staging - Testing when deployed on a live stage environment like its on the real thing

// fuzzing
// stateful fuzz
// stateless fuzz
// formal verification

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {AddConsumer, FundSubscription, CreateSubscription} from "script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract Interactions is Test {}
