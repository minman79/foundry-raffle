// SPDX-License-Identifier: MIT

/* VERSION */
pragma solidity 0.8.19;

/**
 * @title A sample Raffle contract
 * @author Minesh Patel
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {
    /* ERRORS */
    error Raffle__SendMoreToEnterRaffle();

    /* STATE VARIABLE */
    // Made this immutable so we can define entranceFee when creating contracts
    // As it is private, created a getter function
    uint256 private immutable i_entranceFee;
    // I want to set the interval once between lottery rounds
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;

    // addresses array of players needs to be payable to pay the winners address
    address payable[] private s_players;

    uint256 private s_lastTimeStamp;

    /* EVENTS */
    // 1. Makes migration easier
    // 2. Makes front end "indexing" easier
    // This event is a new player has entered our raffle which is indexed
    event RaffleEntered(address indexed player);

    /* FUNCTIONS */
    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
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
        // we need this payable as the array we are pushing it to is payable
        s_players.push(payable(msg.sender));
        // Needed anytime we update our Storage variable
        // Emits to our Event the address of our new player
        emit RaffleEntered(msg.sender);
    }

    // 1. Get a random number
    // 2. Use random number to pick a player
    // 3. Makes front end "indexing" easier
    function pickWinner() external {
        // has enough time passed using block.timestamp till we can pick a winner
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
    }

    /**
     * Getter Functions  (external so they can be used in other contracts)
     */
    function getEntranceFee() external view returns (uint256 entranceFee) {
        return i_entranceFee;
    }
}
