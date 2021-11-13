pragma solidity 0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract GetYourRollOn is Ownable, VRFConsumerBase {
    using SafeMathChainlink for uint256;

    struct Seeds {
        uint256 nonce; //for chainlink seed
        uint256 randomSeed; // current nulti-roll seed
        uint256 seedLife; // how many bocks it's good for
        uint256 lastSeed; // last block we checked
        bytes32 requestId; // request ID of the pending call
    }

    struct Player {
        uint256 totalRolls;
        uint256 lastRoll;
        bool isRolling;
    }

    // store the seeds in a private var
    Seeds private seeds;

    // public player data
    mapping (address => Player) public players;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal linkFee;
    address internal vrfCoordinator;

    event Roll(address indexed user, uint256 rollNum);

    //-----------------------------

    constructor(
        address _vrfCoordinator,
        bytes32 _vrfKeyHash, 
        address _linkToken,
        uint256 _linkFee
    ) VRFConsumerBase (
        _vrfCoordinator, 
        _linkToken
    )   public {      
        vrfCoordinator = _vrfCoordinator;
        keyHash = _vrfKeyHash;
        linkFee = _linkFee;

        // get the first random seed
        seeds.requestId = requestRandomness(keyHash, linkFee);
  
    }

    /** 
    * @notice Modifier to only allow updates by the VRFCoordinator contract
    */
    modifier onlyVRFCoordinator {
        require(msg.sender == vrfCoordinator, 'VRF Only');
        _;
    }

    /**
     * @dev Simple Roll function to demo. will get a number between 2-12 
     * @dev If the current block number is past the seed life we grab a new seed
     */
    function roll() external  {
        // don't let them roll twice at the same time
        require(!players[msg.sender].isRolling, "Already Rolling");

        // make sure we've gotten back our first seed
        require(seeds.randomSeed > 0, "Waiting for Chainlink");

        // set the player as rolling
        players[msg.sender].isRolling = true;

        // check if we're past the seed life or don't have a request ID
        if(seeds.requestId == 0  && block.number >= seeds.lastSeed.add(seeds.seedLife)){
            
            // make sure there is link to cover the fee
            require(LINK.balanceOf(address(this)) > linkFee, "No LINK");

            // send off for a new request to chainlink
            seeds.requestId = requestRandomness(keyHash, linkFee);
         } 

         // get a number between 2-12
         uint _roll = (uint(keccak256(abi.encodePacked(now, msg.sender, seeds.randomSeed))) % 11) + 2;

         // increment the seed for the next use
         seeds.randomSeed++;    

         // update player stats
         players[msg.sender].lastRoll = _roll;
         players[msg.sender].totalRolls++;

         //end the roll
         players[msg.sender].isRolling = false;

         emit  Roll(msg.sender, _roll);
    }

    /**
     * @notice Callback function used by VRF Coordinator
     * @dev The VRF Coordinator will only send this function verified responses.
     * @dev The VRF Coordinator will not pass randomness that could not be verified.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override onlyVRFCoordinator {
        // sets the seed
        seeds.randomSeed = randomness;
        // set the last block
        seeds.lastSeed = block.number;
        // clear the request
        seeds.requestId = 0;
    }
}