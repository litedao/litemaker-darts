import 'erc20/erc20.sol';
import 'game.sol';

contract MakerDartsLobby {
  event GamePending(address game);

  function createZeroSumGame(uint betSize, ERC20 betAsset)
      returns (address) {
    return createZeroSumGame(betSize, betAsset, false);
  }

  function createZeroSumGame(uint betSize, ERC20 betAsset, bool debug)
      returns (address) {
    var game = new MakerDartsGame(betSize, betAsset, debug);

    // Default settings.
    game.setParticipants(5);
    game.setParticipantReward(0);
    game.setCommitmentBlocks(12);
    game.setRevealBlocks(12);
    game.setCalculationBlocks(12);
    game.setWinnerCut(50);
    game.setWinners(3);
    game.setOwner(msg.sender);

    if (!debug) {
      GamePending(game);
    }
    return game;
  }

  function createGame(uint betSize, ERC20 betAsset, bool debug)
      returns (address) {
    var game = new MakerDartsGame(betSize, betAsset, debug);

    if (!debug) {
      GamePending(game);
    }
    return game;
  }
}
