pragma solidity 0.6.12;

/**
 * 
 * Simple proxy contract for balanceOf
 * Used to let collab land get a balance of staked tokens/lp
 * but the logic can be anything that returns a number and could
 * be used for any service that just needs a balance
 * 
 * The first example checks master chef for a balance of a pool
 * 
 * the second example is what we used for memenopoly to allow
 * people that have X or more NFT sets staked access to our VIP room,
 * but is an example of custom logic that could be used with any contract
 * 
 */



//masterchef contract
import './TheBanker.sol';
import './TheBroker.sol';


contract CLProxy {
    TheBanker public theBanker;
    uint256 pId;

    constructor (
        TheBanker _banker, // contract address
        uint256 _pid // pool id
    ) public {
        theBanker = _banker;
        pId = _pid;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        // read the userInfo struct for this account/pool id and return the ammount
        (uint256 amt, uint256 dbt) = theBanker.userInfo(pId,account);
        return amt;
    }
}


contract CLNFTProxy {
    TheBroker public theBroker;
    uint256 pId;
    constructor (
        TheBroker _broker
    ) public {
        theBroker = _broker;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        uint256 fullSets;
        // calls a custom function from the contract and we total the number of full sets
        bool[] memory sets = theBroker.getFullSetsOfAddress(account);
        
        for (uint256 i = 0; i < sets.length; ++i) {
            if (sets[i]){
                fullSets += 1;
            }
        }
        return fullSets;
    }
}