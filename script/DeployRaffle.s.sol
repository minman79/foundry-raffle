// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Raffle} from "src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployContract() public returns (Raffle, HelperConfig) {}
}
