// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/*

.-------. .-./`) _____     __   ,-----.  ,---------.   _______   .---.  .---..-./`)
\  _(`)_ \\ .-.')\   _\   /  /.'  .-,  '.\          \ /   __  \  |   |  |_ _|\ .-.')
| (_ o._)|/ `-' \.-./ ). /  '/ ,-.|  \ _ \`--.  ,---'| ,_/  \__) |   |  ( ' )/ `-' \
|  (_,_) / `-'`"`\ '_ .') .';  \  '_ /  | :  |   \ ,-./  )       |   '-(_{;}_)`-'`"`
|   '-.-'  .---.(_ (_) _) ' |  _`,/ \ _/  |  :_ _: \  '_ '`)     |      (_,_) .---.
|   |      |   |  /    \   \: (  '\_/ \   ;  (_I_)  > (_)  )  __ | _ _--.   | |   |
|   |      |   |  `-'`-'    \\ `"/  \  ) /  (_(=)_)(  .  .-'_/  )|( ' ) |   | |   |
/   )      |   | /  /   \    \'. \_/``".'    (_I_)  `-'`-'     / (_{;}_)|   | |   |
`---'      '---''--'     '----' '-----'      '---'    `._____.'  '(_,_) '---' '---'

https://t.me/Pixotchi
https://twitter.com/pixotchi
https://pixotchi.tech/
@audit https://blocksafu.com/
*/

// Importing necessary components from OpenZeppelin's upgradeable contracts library.
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

// Interface for the Pixotchi NFT that this game contract will interact with.
interface IPixotchiNFTforBoxGame {
    enum  Status {
        JOYFUL, //0
        THIRSTY, //1
        NEGLECTED, //2
        SICK, //3
        DEAD, //4,
        BURNED //5
    }

    struct Plant {
        uint256 id;
        string name;
        Status status;
        uint256 score;
        uint256 level;
        uint256 timeUntilStarving;
        uint256 lastAttacked;
        uint256 lastAttackUsed;
        address owner;
        uint256 rewards;
        uint256 stars;
    }
    // Function to update points and rewards for an NFT.
    //function updatePointsAndRewards(uint256 _nftId, uint256 _points, uint256 _timeExtension) external;
    // Function to get the owner of a specific NFT.
    function ownerOf(uint256 tokenId) external view returns (address owner);
    // check that Plant didn't starve
    function isPlantAlive(uint256 _nftId) external view returns (bool);

    function getPlantInfo(uint256 _nftId) external view returns (Plant memory);

    // Declaration for updatePointsAndRewardsV2 function
    function updatePointsAndRewardsV2(uint256 _nftId, int256 _pointsAdjustment, int256 _timeAdjustment) external;
}

// Main game contract, inheriting from OpenZeppelin's upgradeable contracts.
contract SpinGame is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    // State variables for the game.
    IPixotchiNFTforBoxGame public nftContract; // Reference to the NFT contract.
    uint256 public coolDownTime; // Cooldown time between plays for each NFT.
    uint256 public nftContractRewardDecimals; // Decimals for reward calculation.
    mapping(uint256 => uint256) public lastPlayed; // Tracks last played time for each NFT.
    //uint256[] public pointRewards; // Array storing point rewards.
    //uint256[] public timeRewards; // Array storing time rewards.

    struct Reward {
        int256 points; // Can be negative for deductions.
        int256 timeAdjustment; // Can be negative for reductions. Represented in seconds.
        bool isPercentage; // True if the adjustments are percentage-based.
    }

    Reward[] public rewards; // Array storing all possible rewards.
    // Function to initialize the contract. Only callable once.
    function initialize(address _nftContract) initializer public {
        nftContract = IPixotchiNFTforBoxGame(_nftContract); // Set the NFT contract.
        coolDownTime = 24 hours; // Default cooldown time.
        nftContractRewardDecimals = 1e12; // Set the reward decimals.
        __Ownable_init(); // Initialize the Ownable contract.
        __ReentrancyGuard_init(); // Initialize the ReentrancyGuard contract.
        //pointRewards = [0 * 1e12,0 * 1e12,0 * 1e12,0 * 1e12,0 * 1e12,0]; // Initialize point rewselectedRewardards.
        //timeRewards = [0, 3 hours , 5 hours, 7 hours, 9 hours]; // Initialize time rewards.
        rewards.push(Reward(0, 6 hours, false)); // +6H TOD
        rewards.push(Reward(0, 12 hours, false)); // +12H TOD
        rewards.push(Reward(150 * 1e12, 0, false)); // +150 Points
        rewards.push(Reward(0, - 15, true)); // -15% TOD
        rewards.push(Reward(- 10, 0, true)); // -10% Points
        rewards.push(Reward(0, 0, false)); // Nothing


    }

//  // Function to allow users to play the game with a specific NFT.
//  function play(uint256 nftID, uint256 seed) public nonReentrant returns (uint256 points, uint256 timeExtension)  {
//    // Ensure the caller is the owner of the NFT and meets other requirements.
//    require(nftContract.ownerOf(nftID) == msg.sender, "Not the owner of nft");
//    require(seed > 0 && seed < 10, "Seed should be between 1-9");
//    require(getCoolDownTimePerNFT(nftID) == 0, "Cool down time has not passed yet");
//    require(nftContract.isPlantAlive(nftID), "Plant is dead");
//
//    // Generate random indices for points and time rewards.
//    uint256 pointsIndex = random(seed, 0, pointRewards.length - 1);
//    points = pointRewards[pointsIndex];
//    uint256 timeIndex = random2(seed, 0, timeRewards.length - 1);
//    timeExtension = timeRewards[timeIndex];
//
//    // Record the current time as the last played time for this NFT.
//    lastPlayed[nftID] = block.timestamp;
//
//    // Update the NFT with new points and time extension.
//    nftContract.updatePointsAndRewards(nftID, points, timeExtension);
//
//    // Return the points and time extension.
//    return (points, timeExtension);
//  }

    function play(uint256 nftID, uint256 seed) public nonReentrant returns (int256 pointsAdjustment, int256 timeAdjustment) {
        // Ensure the caller is the owner of the NFT and meets other requirements.
        require(nftContract.ownerOf(nftID) == msg.sender, "Not the owner of nft");
        require(seed > 0 && seed < 10, "Seed should be between 1-9");
        require(getCoolDownTimePerNFT(nftID) == 0, "Cool down time has not passed yet");
        require(nftContract.isPlantAlive(nftID), "Plant is dead");

      //Reward memory selectedReward = getRandomWithRetries(seed, 0, (rewards.length - 1));
      uint256 selector = getRandomWithRetries(seed, 0, (rewards.length - 1));
      Reward memory selectedReward = rewards[selector];
      //Reward memory selectedReward = getRandomWithRetries(seed, 0, (rewards.length - 1));



        // Fetch the current state of the plant.
        IPixotchiNFTforBoxGame.Plant memory plant = nftContract.getPlantInfo(nftID);

        // Calculate adjustments based on the selected reward.
        if (selectedReward.isPercentage) {
            if (selectedReward.points != 0) {
                pointsAdjustment = int256(plant.score) * selectedReward.points / 100;
            }
            if (selectedReward.timeAdjustment != 0) {
                timeAdjustment = int256(plant.timeUntilStarving) * selectedReward.timeAdjustment / 100;
            }
        } else {
            pointsAdjustment = selectedReward.points;
            timeAdjustment = selectedReward.timeAdjustment;
        }

        // Apply adjustments to the plant.
        lastPlayed[nftID] = block.timestamp;
        nftContract.updatePointsAndRewardsV2(nftID, pointsAdjustment, timeAdjustment);

        return (pointsAdjustment, timeAdjustment);
    }

    // Function to get the remaining cooldown time for an NFT.
    function getCoolDownTimePerNFT(uint256 nftID) public view returns (uint256) {
        uint256 lastPlayedTime = lastPlayed[nftID];
        // Return 0 if the NFT has never been played.
        if (lastPlayedTime == 0) {
            return 0;
        }
        // Check if the current time is less than the last played time (edge case).
        if (block.timestamp < lastPlayedTime) {
            return coolDownTime;
        }
        // Calculate the time passed since last played.
        uint256 timePassed = block.timestamp - lastPlayedTime;
        // Return 0 if the cooldown has passed, otherwise return remaining time.
        if (timePassed >= coolDownTime) {
            return 0;
        }
        return coolDownTime - timePassed;
    }

    // Function for the contract owner to set the global cooldown time.
    function setGlobalCoolDownTime(uint256 _coolDownTime) public onlyOwner {
        coolDownTime = _coolDownTime;
    }

//  //set pointRewards
//  function setPointRewards(uint256[] memory _pointRewards) public onlyOwner {
//    pointRewards = _pointRewards;
//  }
//
//  //set timeRewards
//  function setTimeRewards(uint256[] memory _timeRewards) public onlyOwner {
//    timeRewards = _timeRewards;
//  }

    // Function to set new rewards. Only callable by the contract owner.
    function setRewards(Reward[] memory newRewards) public onlyOwner {
        delete rewards; // Clear the current rewards array.
        for (uint i = 0; i < newRewards.length; i++) {
            rewards.push(newRewards[i]); // Add new rewards to the array.
        }
    }

// Function to get the length of the rewards array.
    function getRewardsLength() public view returns (uint) {
        return rewards.length;
    }

    //  function to generate a pseudo-random number based on several blockchain parameters.
    function random(uint256 seed, uint256 min, uint256 max) public view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.prevrandao, seed, block.number)));
        return min + (randomHash % (max - min + 1));
    }

    // Secondary  function for random number generation.
    function random2(uint256 seed, uint256 min, uint256 max) public view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(seed, block.prevrandao, block.timestamp, msg.sender)));
        return min + (randomHash % (max - min + 1));
    }

    //uint256
    function random3(uint256 seed, uint256 min, uint256 max) public view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.prevrandao, seed, block.number)));
        return min + (randomHash % (max - min + 1));
    }

    //uint256

    function random4(uint256 seed, uint256 min, uint256 max) public view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(seed, block.prevrandao, block.timestamp, msg.sender)));
        return min + (randomHash % (max - min + 1));
    }

    //no input
    function random5() public view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp
        )));
        return randomHash;
    }

    function random6(uint256 min, uint256 max) public view returns (uint256) {
        uint256 randomHash = random5();
        uint256 returnValue = min + (randomHash % (max - min + 1));
        return returnValue;
    }



  event RandomSuccess(uint result);
  event RandomFailure(string reason);

    // Function to attempt to get a random number with retries across multiple random functions
    function getRandomWithRetries(uint256 seed, uint256 min, uint256 max) public returns (uint256) {
        // Try each random function in sequence
        try this.random(seed, min, max) returns (uint256 result) {
            emit RandomSuccess(result);
            return result;
        } catch {
            try this.random2(seed, min, max) returns (uint256 result) {
                emit RandomSuccess(result);
                return result;
            } catch {
                try this.random3(seed, min, max) returns (uint256 result) {
                    emit RandomSuccess(result);
                    return result;
                } catch {
                    try this.random4(seed, min, max) returns (uint256 result) {
                        emit RandomSuccess(result);
                        return result;
                    } catch {
                        try this.random6(min, max) returns (uint256 result) {
                            emit RandomSuccess(result);
                            return result;
                        } catch {
                            emit RandomFailure("All random generation attempts failed");
                            revert("All attempts to generate a random number failed.");
                        }
                    }
                }
            }
        }
    }

}
