// SPDX-License-Identifier: MIT

/* VERSION */
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author Minesh Patel
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

// inherited all the functions from the VRFConsumerBaseV2Plus contract to use with ours
contract Raffle is VRFConsumerBaseV2Plus {
    /* ERRORS */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    /* TYPE DECLARATIONs */
    // Enums used to create custom finite types of 'constant values'
    enum RaffleState {
        OPEN, // 0 - players can enter the raffle
        CALCULATING // 1 - calculating so players cannot enter raffle

    }

    /* STATE VARIABLES */
    // Made this immutable so we can define entranceFee when creating contracts
    // As it is private, created a getter function

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    // I want to set the interval once between lottery rounds
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    // addresses array of players needs to be payable to pay the winners address
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* EVENTS */
    // 1. Makes migration easier
    // 2. Makes front end "indexing" easier
    // This event is a new player has entered our raffle which is indexed
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    /* FUNCTIONS */
    // As VRFConsumerBaseV2Plus contract has a constructor parameter, using my constructor to get the vrfCoordinator address and pass it to their constructor
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN; // or RaffleState(0)
    }

    // Needs to be payable to receive funds
    function enterRaffle() external payable {
        // Not Gas Efficient because of String
        // require(msg.value >= i_entranceFee, "Not enough ETH sent");

        // solidity ^0.8.20 but negligibly less gas efficient
        // require(msg.value >= i_entranceFee, Raffle__SendMoreToEnterRaffle());

        // Solidity ^0.8.4 Most gas efficient but harder to read than latest method - (default to this)
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        // we need this payable as the array we are pushing it to is payable
        s_players.push(payable(msg.sender));
        // Needed anytime we update our Storage variable
        // Emits to our Event the address of our new player
        emit RaffleEntered(msg.sender);
    }

    // This checks when is it ready to pick a winner
    /**
     * @dev This is the function that the Chainlink nodes will call to see if the lottery is ready to have a winner picked.
     * The following should be true to have a winner picked.
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open 
     * 3. The contract has ETH (Does it have players)
     * 4. Implicitly, your subscription has LINK
     * @param - ignored 
     * @return upkeepNeeded - true if it's time to restart the lottery 
     * @return - ignored
     */
    function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* preformData */) {  // upkeepNeeded is initalized in this form and defaults to false
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return(upkeepNeeded, "");
        }
    }

    // 1. Get a random number  -- Chainlink VRF
    // 2. Use random number to pick a player -- fulfillRandomWords()
    // 3. Be automatically called -- Chainlink Automation
    function performUpkeep(bytes calldata /* performData */) external {
        // has enough time passed using block.timestamp till we can pick a winner
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert();
        }

        s_raffleState = RaffleState.CALCULATING;

        // Get our random number from Chainlink VRF v2.5 which is a 2 part process
        // 1. Request RNG (Random Number Generator)
        // 2. Get RNG
        // copied from https://docs.chain.link/vrf/v2-5/getting-started, so need to import the contract
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash, // maximum gas price (wei) I am willing to pay
                subId: i_subscriptionId, // SubId that this contract uses for funding requests
                requestConfirmations: REQUEST_CONFIRMATIONS, // No. of confirmation Chainlink node should wait till responding. Higher == more secure. Default is 3
                callbackGasLimit: i_callbackGasLimit, // gas limit to use for the callback request
                numWords: NUM_WORDS, // How many random values to request
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    // Added this because we inherited VRFConsumerBaseV2Plus ABSTRACT contract which had this undefined function which we need to define with an override to replace the virtual keyword
    // Used to define what are we going to do with the random number we get back
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // CHECKS (Conditionals if/require statements as more gas efficient to revert at this stage)

        // EXAMPLE s_players = 10, rng = 131505 --- 131505 % 10 = 5 -- player at index 5 wins --- modulo provides me numbers 0-9 which includes 10 players
        // Index of randomWords is 0 as we are only getting one RNG back.

        // EFFECTS (Internal Contract States)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        // resets the s_players array to zero for the new raffle and updates timeStamp
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner); // Best practise to put this in EFFECTS in the event an external contract interactions does change your storage variable

        // transfer funds in contract to the winner

        // INTERACTIONS (External Contract Interactions)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions  (external so they can be used in other contracts)
     */
    function getEntranceFee() external view returns (uint256 entranceFee) {
        return i_entranceFee;
    }
}
