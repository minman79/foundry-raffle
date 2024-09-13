// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player); // have to copy paste any events to the top of our Test contract
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // ARRANGE
        vm.prank(PLAYER);
        // ACT / ASSET
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // ARRANGE
        vm.prank(PLAYER);
        // ACT
        raffle.enterRaffle{value: entranceFee}();
        // ASSET
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    // function testEnteringRaffleEmitsEvent() public {
    //     // ARRANGE
    //     vm.prank(PLAYER);
    //     // ASSET
    //     vm.expectEmit(true, false, false, false, address(raffle)); // first three refers to indexed parameters (topics), and last false for non-indexed which we have none, and it is the address of the raffle which is going to be emitting this
    //     emit RaffleEntered(PLAYER);  // emit RaffleEntered(address(0)); would fail as it will expect 0X00000.. as raffle has not been run
    //     // ACT
    //     raffle.enterRaffle{value: entranceFee}();
    // }
}
