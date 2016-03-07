import 'makeruser/generic.sol';
import 'makeruser/interfaces.sol';

contract Owned {
  address public owner;

  function Owned () {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) throw;
    _
  }

  function setOwner(address newOwner) onlyOwner {
    owner = newOwner;
  }
}

contract MakerDartsGame is MakerUserGeneric, Owned {
  uint public betSize;
  bytes32 public betAsset;
  uint public participants;
  uint public participantReward;
  uint public commitmentBlocks;
  uint public revealBlocks;
  uint public calculationBlocks;
  uint public startingBlock; // 0 - the game hasn't started.
  uint public winnerCut;
  bool public debug;

  event GameStarted();
  event Commit(address sender, bytes32 betHash, address recipient);
  event Reveal(bytes32 betHash, bytes32 betTarget, bytes32 betSalt);
  event Result(bytes32 result, uint distance);
  event Claim(bytes32 commitHash, uint payout);

  struct Bet {
    bytes32 commitHash;
    address recipient;
    bytes32 target;
    bytes32 salt;
    bytes32 result;
    uint distance;
    bool claimed;
  }

  mapping(bytes32=>Bet) public bets;
  bytes32[] public betKeys;
  bytes32[] public winnerKeys;
  uint _numCompleters;
  bool _claimed;

  uint _debugBlock;

  modifier beforeGame() {
    if (startingBlock != 0) throw;
    _
  }

  modifier commitmentRound() {
    if (startingBlock == 0 ||
        blockNumber() < startingBlock ||
        blockNumber() >= startingBlock + commitmentBlocks) {
      throw;
    }
    _
  }

  modifier revealingRound() {
    if (startingBlock == 0 ||
        betKeys.length < participants ||
        blockNumber() < startingBlock + commitmentBlocks ||
        blockNumber() >= startingBlock + commitmentBlocks + revealBlocks) {
      throw;
    }
    _
  }

  modifier calculationRound() {
    if (startingBlock == 0 ||
        betKeys.length < participants ||
        blockNumber() < startingBlock + commitmentBlocks + revealBlocks ||
        blockNumber() >= startingBlock + commitmentBlocks + revealBlocks +
         calculationBlocks) {
      throw;
    }
    _
  }

  modifier claimRound() {
    var gameBlocks = (commitmentBlocks + revealBlocks + calculationBlocks);
    if (startingBlock == 0 ||
        betKeys.length < participants ||
        blockNumber() < startingBlock + gameBlocks ||
        blockNumber() >= startingBlock + (gameBlocks * 2)) {
      throw;
    }
    _
  }

  modifier afterGame() {
    if (blockNumber() != 0 && (startingBlock == 0 ||
        blockNumber() < startingBlock + (commitmentBlocks + revealBlocks +
                                        calculationBlocks) * 2)) {
      throw;
    }
    _
  }

  function MakerDartsGame (MakerTokenRegistry registry,
                           uint _betSize,
                           bytes32 _betAsset,
                           bool _debug)
           MakerUserGeneric (registry) {

    betSize = _betSize;
    betAsset = _betAsset;
    debug = _debug;
  }

  function setParticipants (uint numParticipants) onlyOwner beforeGame {
    participants = numParticipants;
  }

  function setParticipantReward(uint reward) onlyOwner beforeGame {
    participantReward = reward;
  }

  function setCommitmentBlocks (uint blocks) onlyOwner beforeGame {
    commitmentBlocks = blocks;
  }

  function setRevealBlocks(uint blocks) onlyOwner beforeGame {
    revealBlocks = blocks;
  }

  function setCalculationBlocks(uint blocks) onlyOwner beforeGame {
    calculationBlocks = blocks;
  }

  function setWinnerCut(uint8 percent) onlyOwner beforeGame {
    winnerCut = percent;
  }

  function setWinners(uint numWinners) onlyOwner beforeGame {
    winnerKeys.length = numWinners;
  }

  function commitBet(bytes32 commitHash, address payoutRecipient)
      commitmentRound {
    if (bets[commitHash].recipient != 0x0 || payoutRecipient == 0x0) {
      throw;
    }
    bets[commitHash].recipient = payoutRecipient;
    betKeys.push(commitHash);
    transferFrom(msg.sender, this, betSize, betAsset);
    Commit(msg.sender, commitHash, bets[commitHash].recipient);
  }

  function revealBet(bytes32 commitHash, bytes32 target, bytes32 salt)
      revealingRound {
    if (commitHash != sha3(salt, target) || bets[commitHash].recipient == 0x0) {
      throw;
    }
    bets[commitHash].target = target;
    bets[commitHash].salt = salt;
    Reveal(commitHash, target, salt);
  }

  function calculateResult(bytes32 commitHash)
      calculationRound returns (bytes32){
    if (bets[commitHash].salt == 0x0 && bets[commitHash].target == 0x0) {
      throw;
    }

    Bet memory currBet;
    var result = commitHash;
    for (uint i = 0; i < betKeys.length; i += 1) {
      currBet = bets[betKeys[i]];
      if (currBet.salt == 0x0 && currBet.target == 0x0
          || betKeys[i] == commitHash) {
        continue;
      }
      result = sha3(currBet.salt, sha3(currBet.target, result));
    }
    bets[commitHash].result = result;
    _numCompleters += 1;

    uint256 maxKey = 0;
    uint256 maxDistance = 0;
    bets[commitHash].distance = uint(bets[commitHash].target | result);
    for (uint j = 0; j < winnerKeys.length; j += 1) {
      if (bets[winnerKeys[j]].distance > maxDistance) {
        maxKey = j;
        maxDistance = bets[winnerKeys[j]].distance;
      }
      if (winnerKeys[j] == 0x0) {
        winnerKeys[j] = commitHash;
        maxDistance = 0;
        break;
      }
    }
    if (bets[commitHash].distance < maxDistance) {
      winnerKeys[maxKey] = commitHash;
    }
    Result(bets[commitHash].result, bets[commitHash].distance);
    return result;
  }

  function getResult(bytes32 commitHash) constant returns (bytes32) {
    return bets[commitHash].result;
  }

  function claim(bytes32 commitHash) claimRound {
    if (bets[commitHash].result == 0x0 || bets[commitHash].claimed) {
      throw;
    }
    var winnerPayout = (betSize * winnerCut) / 100;
    var totalPayout = (betSize - winnerPayout) + participantReward;

    bool winner = false;
    for (uint i = 0; i < winnerKeys.length; i += 1) {
      if (winnerKeys[i] == commitHash) {
        totalPayout = betSize +
          (winnerPayout * (betKeys.length - winnerKeys.length)
           / winnerKeys.length) + participantReward;
        break;
      }
    }
    transfer(bets[commitHash].recipient, totalPayout, betAsset);
    Claim(commitHash, totalPayout);
    bets[commitHash].claimed = true;
    _claimed = true;
  }

  function refundable(bytes32 commitHash) constant returns (bool) {
    var afterClaimRound = startingBlock + (commitmentBlocks +
                            revealBlocks + calculationBlocks) * 2;

    return (startingBlock != 0 || blockNumber() == 0) &&
            bets[commitHash].recipient != 0x0 &&
            ((betKeys.length < participants) ||
             (!_claimed && blockNumber() >= afterClaimRound));
  }

  function requestRefund(bytes32 commitHash) {
    // If we get into a situation where nobody can calculate their results due
    // to too many participants, then we want to give people the option of
    // claiming a refund of their assets.
    if (!refundable(commitHash)) {
      throw;
    }
    transfer(bets[commitHash].recipient, betSize + participantReward, betAsset);
    delete bets[commitHash];

    if (balanceOf(this, betAsset) == 0) {
      selfdestruct(owner);
    }
  }

  function startGame(bytes32 commitHash, address recipient) onlyOwner beforeGame {
    if (participantReward > 0) {
      transferFrom(msg.sender, this,
                   participantReward * participants, betAsset);
    }
    startingBlock = blockNumber();
    commitBet(commitHash, recipient);
    GameStarted();
  }

  function getBet(bytes32 commitHash) constant
      returns (address, bytes32, bytes32, bytes32, uint) {
    return (bets[commitHash].recipient, bets[commitHash].result,
            bets[commitHash].target, bets[commitHash].salt,
            bets[commitHash].distance);
  }

  function setBlockNumber(uint number) {
    _debugBlock = number;
  }

  function blockNumber() returns (uint) {
    return debug ? _debugBlock : block.number;
  }
}
