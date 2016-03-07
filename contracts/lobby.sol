import 'dapple/debug.sol';
import 'makeruser/generic.sol';
import 'makeruser/interfaces.sol';
import 'game.sol';

contract MakerDartsLobby is MakerUserGeneric {
  event GamePending(address game);

  function MakerDartsLobby (MakerTokenRegistry registry)
           MakerUserGeneric (registry) {}

  function createZeroSumGame(uint betSize, bytes32 betAsset)
      returns (address) {
    return createZeroSumGame(betSize, betAsset, false);
  }

  function createZeroSumGame(uint betSize, bytes32 betAsset, bool debug)
      returns (address) {
    var game = new MakerDartsGame(_M, betSize, betAsset, debug);

    // Default settings.
    game.setParticipants(5);
    game.setParticipantReward(5);
    game.setCommitmentBlocks(12);
    game.setRevealBlocks(12);
    game.setCalculationBlocks(12);
    game.setWinnerReward(50);
    game.setWinners(3);
    game.setOwner(msg.sender);

    if (!debug) {
      GamePending(game);
    }
    return game;
  }

  function createGame(uint betSize, bytes32 betAsset, bool debug)
      returns (address) {
    var game = new MakerDartsGame(_M, betSize, betAsset, debug);

    if (!debug) {
      GamePending(game);
    }
    return game;
  }
}
