// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();
    // Needed for the Constructor parameters which information differs from chain to chain

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[11155111] = getSepoliaEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, // https://docs.chain.link/vrf/v2-5/supported-networks
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // same doc - 100 gwei Key Hash
            subscriptionId: 0, // NEED TO KNOW WHY
            callbackGasLimit: 500000 // 500,000 gas
        });
    }

    function getOrCreateAnvilEthConfig() public view returns (NetworkConfig memory) {
        // check to see if we set an active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
    }
}
