import 'makeruser/generic.sol';
import 'makeruser/user_test.sol';
import 'lobby.sol';


contract MakerDartsActor is MakerUserGeneric {
  MakerDartsLobby lobby;
  MakerDartsGame game;
  bytes32 public betHash;

  function MakerDartsActor (MakerTokenRegistry registry,
                            MakerDartsLobby _lobby)
           MakerUserGeneric (registry) {
    lobby = _lobby;
  }

  function setGame (MakerDartsGame _game) {
    game = _game;
  }

  function setBetHash (bytes32 _betHash) {
    betHash = _betHash;
  }

  function createGame (uint bet, bytes32 asset)
      returns (MakerDartsGame) {
    var game = MakerDartsGame(lobby.createGame(bet, asset, true));
    game.setBlockNumber(1);
    return game;
  }

  function createZSGame (uint bet, bytes32 asset)
      returns (MakerDartsGame) {
    var zsGame = MakerDartsGame(lobby.createZeroSumGame(bet, asset, true));
    zsGame.setBlockNumber(1);
    return zsGame;
  }

  function doSetCommitmentBlocks(uint blocks) {
    game.setCommitmentBlocks(blocks);
  }

  function doSetRevealBlocks(uint blocks) {
    game.setRevealBlocks(blocks);
  }

  function doSetCalculationBlocks(uint blocks) {
    game.setCalculationBlocks(blocks);
  }

  function doSetParticipantReward(uint participantReward) {
    game.setParticipantReward(participantReward);
  }

  function doStartGame() {
    game.startGame(betHash);
  }

  function doApprove(address spender, uint value, bytes32 symbol) {
    approve(spender, value, symbol);
  }

  function doJoinGame(address bettor) {
    game.joinGame(betHash, bettor);
  }

  function doRevealBet(bytes32 target, bytes32 salt) {
    game.revealBet(betHash, target, salt);
  }

  function doCalculateResult() returns (bytes32) {
    return game.calculateResult(betHash);
  }

  function doClaim() {
    game.claim(betHash);
  }

  function doRequestRefund() {
    game.requestRefund(betHash);
  }

  function balanceIn(bytes32 asset) returns (uint) {
    return balanceOf(this, asset);
  }
}

contract MakerLobbyTest is MakerUserTest {
  MakerDartsLobby lobby;
  MakerDartsActor alice;
  MakerDartsActor albert;
  MakerDartsActor bob;
  MakerDartsActor barb;
  MakerDartsActor izzy;

  bytes32 constant betAsset = 'DAI';
  uint constant betSize = 1000;

  bytes32 constant aliceSalt = 0xdeadbeef0;
  bytes32 constant aliceTarget = 0x7a26e70;

  bytes32 constant albertSalt = 0xdeadbeef1;
  bytes32 constant albertTarget = 0x7a26e71;

  bytes32 constant bobSalt = 0xdeadbeef2;
  bytes32 constant bobTarget = 0x7a26e72;

  bytes32 constant barbSalt = 0xdeadbeef3;
  bytes32 constant barbTarget = 0x7a26e73;

  bytes32 constant izzySalt = 0xdeadbeef4;
  bytes32 constant izzyTarget = 0x7a26e74;

  function setUp() {
    MakerUserTest.setUp();
    lobby = new MakerDartsLobby(_M);
    alice = new MakerDartsActor(_M, lobby);
    albert = new MakerDartsActor(_M, lobby);
    bob = new MakerDartsActor(_M, lobby);
    barb = new MakerDartsActor(_M, lobby);
    izzy = new MakerDartsActor(_M, lobby);

    transfer(alice, betSize, betAsset);
    transfer(albert, betSize, betAsset);
    transfer(bob, betSize, betAsset);
    transfer(barb, betSize, betAsset);
    transfer(izzy, betSize, betAsset);
  }

  function testFailBetWithoutApproval () {
    bytes32 salt = 0xdeadbeef;
    bytes32 target = 0x7a26e7;
    alice.setBetHash(sha3(salt, target));

    alice.setGame(alice.createZSGame(betSize, 'DAI'));
    alice.doStartGame();
  }

  function testCreateZeroSumMakerGame () logs_gas {
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    assertEq(game.participantReward(), 0);
    assertEq(game.betSize(), betSize);
    assertEq32(game.betAsset(), betAsset);
  }

  function testFailAtDoubleBetting () logs_gas {
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    alice.setGame(game);
    alice.doApprove(game, betSize, betAsset);
    alice.doStartGame();

    bob.setGame(game);
    bob.setBetHash(sha3(aliceSalt, aliceTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doJoinGame(bob);
  }

  function testStartGame () logs_gas {
    // Create & first commit
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    alice.setGame(game);
    alice.doApprove(game, betSize, betAsset);
    alice.doStartGame();
  }

  function testFullGoldenPathIncentivizedGame () logs_gas {
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = new MakerDartsGame(_M, betSize, betAsset, true);
    game.setBlockNumber(block.number);
    game.setParticipants(5);
    game.setParticipantReward(10);
    game.setCommitmentBlocks(12);
    game.setRevealBlocks(12);
    game.setCalculationBlocks(12);
    game.setWinnerCut(75);
    game.setWinners(2);
    game.setOwner(alice);

    alice.setGame(game);
    albert.setGame(game);
    bob.setGame(game);
    barb.setGame(game);
    izzy.setGame(game);

    transfer(alice, betSize*2, betAsset);
    alice.doApprove(game, betSize*2, betAsset);
    alice.doStartGame();

    // Commit
    albert.setBetHash(sha3(albertSalt, albertTarget));
    albert.doApprove(game, betSize, betAsset);
    albert.doJoinGame(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doJoinGame(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doJoinGame(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doJoinGame(izzy);

    // Advance the game past the commitment round
    game.setBlockNumber(block.number + game.commitmentBlocks());

    // Reveal
    alice.doRevealBet(aliceTarget, aliceSalt);
    albert.doRevealBet(albertTarget, albertSalt);
    bob.doRevealBet(bobTarget, bobSalt);
    barb.doRevealBet(barbTarget, barbSalt);
    izzy.doRevealBet(izzyTarget, izzySalt);

    // Advance the game past the reveal round
    game.setBlockNumber(block.number + game.commitmentBlocks() +
                       game.revealBlocks());

    // Calculate
    alice.doCalculateResult();
    albert.doCalculateResult();
    bob.doCalculateResult();
    barb.doCalculateResult();
    izzy.doCalculateResult();

    // Advance the game past the calculation round
    game.setBlockNumber(block.number + game.commitmentBlocks() +
                       game.revealBlocks() + game.calculationBlocks());

    // Claim
    alice.doClaim();
    albert.doClaim();
    bob.doClaim();
    barb.doClaim();
    izzy.doClaim();

    // Check balances
    assertEq(alice.balanceIn(betAsset), 2210);
    assertEq(albert.balanceIn(betAsset), 260);
    assertEq(bob.balanceIn(betAsset), 2135);
    assertEq(barb.balanceIn(betAsset), 2135);
    assertEq(izzy.balanceIn(betAsset), 260);
  }

  function testFullGoldenPathZeroSumGame () logs_gas {
    // Create & first commit
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    game.setBlockNumber(block.number);

    alice.setGame(game);
    albert.setGame(game);
    bob.setGame(game);
    barb.setGame(game);
    izzy.setGame(game);

    alice.doApprove(game, betSize, betAsset);
    alice.doStartGame();

    // Commit
    albert.setBetHash(sha3(albertSalt, albertTarget));
    albert.doApprove(game, betSize, betAsset);
    albert.doJoinGame(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doJoinGame(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doJoinGame(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doJoinGame(izzy);

    // Advance the game past the commitment round
    game.setBlockNumber(block.number + game.commitmentBlocks());

    // Reveal
    alice.doRevealBet(aliceTarget, aliceSalt);
    albert.doRevealBet(albertTarget, albertSalt);
    bob.doRevealBet(bobTarget, bobSalt);
    barb.doRevealBet(barbTarget, barbSalt);
    izzy.doRevealBet(izzyTarget, izzySalt);

    // Advance the game past the reveal round
    game.setBlockNumber(block.number + game.commitmentBlocks() +
                       game.revealBlocks());

    // Calculate
    alice.doCalculateResult();
    albert.doCalculateResult();
    bob.doCalculateResult();
    barb.doCalculateResult();
    izzy.doCalculateResult();

    // Advance the game past the calculation round
    game.setBlockNumber(block.number + game.commitmentBlocks() +
                       game.revealBlocks() + game.calculationBlocks());

    // Claim
    alice.doClaim();
    albert.doClaim();
    bob.doClaim();
    barb.doClaim();
    izzy.doClaim();

    // Check balances
    assertEq(alice.balanceIn(betAsset), betSize + (betSize / 3));
    assertEq(albert.balanceIn(betAsset), betSize / 2);
    assertEq(bob.balanceIn(betAsset), betSize + (betSize / 3));
    assertEq(barb.balanceIn(betAsset), betSize + (betSize / 3));
    assertEq(izzy.balanceIn(betAsset), betSize / 2);
  }

  function testFullZeroSumGameWithOneUnrevealingPlayer () logs_gas {
    // Create & first commit
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    game.setBlockNumber(block.number);

    alice.setGame(game);
    albert.setGame(game);
    bob.setGame(game);
    barb.setGame(game);
    izzy.setGame(game);

    alice.doApprove(game, betSize, betAsset);
    alice.doStartGame();

    // Commit
    albert.setBetHash(sha3(albertSalt, albertTarget));
    albert.doApprove(game, betSize, betAsset);
    albert.doJoinGame(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doJoinGame(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doJoinGame(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doJoinGame(izzy);

    // Advance the game past the commitment round
    game.setBlockNumber(block.number + game.commitmentBlocks());

    // Reveal
    alice.doRevealBet(aliceTarget, aliceSalt);
    albert.doRevealBet(albertTarget, albertSalt);
    bob.doRevealBet(bobTarget, bobSalt);
    barb.doRevealBet(barbTarget, barbSalt);

    // Advance the game past the reveal round
    game.setBlockNumber(block.number + game.commitmentBlocks() +
                       game.revealBlocks());

    // Calculate
    alice.doCalculateResult();
    albert.doCalculateResult();
    bob.doCalculateResult();
    barb.doCalculateResult();

    // Advance the game past the calculation round
    game.setBlockNumber(block.number + game.commitmentBlocks() +
                       game.revealBlocks() + game.calculationBlocks());

    // Claim
    alice.doClaim();
    albert.doClaim();
    bob.doClaim();
    barb.doClaim();

    // Check balances
    assertEq(alice.balanceIn(betAsset), betSize / 2);
    assertEq(albert.balanceIn(betAsset), betSize + (betSize / 3));
    assertEq(bob.balanceIn(betAsset), betSize + (betSize / 3));
    assertEq(barb.balanceIn(betAsset), betSize + (betSize / 3));
    assertEq(izzy.balanceIn(betAsset), 0);
  }

  function testFullZeroSumGameWithOneUncalculatingPlayer () logs_gas {
    // Create & first commit
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    game.setBlockNumber(block.number);

    alice.setGame(game);
    albert.setGame(game);
    bob.setGame(game);
    barb.setGame(game);
    izzy.setGame(game);

    alice.doApprove(game, betSize, betAsset);
    alice.doStartGame();

    // Commit
    albert.setBetHash(sha3(albertSalt, albertTarget));
    albert.doApprove(game, betSize, betAsset);
    albert.doJoinGame(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doJoinGame(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doJoinGame(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doJoinGame(izzy);

    // Advance the game past the commitment round
    game.setBlockNumber(block.number + game.commitmentBlocks());

    // Reveal
    alice.doRevealBet(aliceTarget, aliceSalt);
    albert.doRevealBet(albertTarget, albertSalt);
    bob.doRevealBet(bobTarget, bobSalt);
    barb.doRevealBet(barbTarget, barbSalt);
    izzy.doRevealBet(izzyTarget, izzySalt);

    // Advance the game past the reveal round
    game.setBlockNumber(block.number + game.commitmentBlocks() +
                       game.revealBlocks());

    // Calculate
    alice.doCalculateResult();
    albert.doCalculateResult();
    bob.doCalculateResult();
    barb.doCalculateResult();

    // Advance the game past the calculation round
    game.setBlockNumber(block.number + game.commitmentBlocks() +
                       game.revealBlocks() + game.calculationBlocks());

    // Claim
    alice.doClaim();
    albert.doClaim();
    bob.doClaim();
    barb.doClaim();

    // Check balances
    assertEq(alice.balanceIn(betAsset), betSize + (betSize / 3));
    assertEq(albert.balanceIn(betAsset), betSize / 2);
    assertEq(bob.balanceIn(betAsset), betSize + (betSize / 3));
    assertEq(barb.balanceIn(betAsset), betSize + (betSize / 3));
    assertEq(izzy.balanceIn(betAsset), 0);
  }

  function testRefundsWithInsufficientPlayers () logs_gas {
    // Create & first commit
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    game.setBlockNumber(block.number);

    alice.setGame(game);
    albert.setGame(game);
    bob.setGame(game);
    barb.setGame(game);

    var participantReward = 10;
    var participantRewardCost = (participantReward * game.participants());
    transfer(alice, participantRewardCost, betAsset);
    alice.doApprove(game, betSize + participantRewardCost, betAsset);
    alice.doSetParticipantReward(participantReward);
    alice.doStartGame();

    // Commit
    albert.setBetHash(sha3(albertSalt, albertTarget));
    albert.doApprove(game, betSize, betAsset);
    albert.doJoinGame(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doJoinGame(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doJoinGame(barb);

    // Advance the game past the commitment round
    game.setBlockNumber(block.number + game.commitmentBlocks());

    // Request refunds
    alice.doRequestRefund();
    albert.doRequestRefund();
    bob.doRequestRefund();
    barb.doRequestRefund();

    // Check balances
    assertEq(alice.balanceIn(betAsset), betSize + participantRewardCost);
    assertEq(albert.balanceIn(betAsset), betSize);
    assertEq(bob.balanceIn(betAsset), betSize);
    assertEq(barb.balanceIn(betAsset), betSize);
  }

  function testRefundsWithoutClaims () logs_gas {
    // Create & first commit
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    game.setBlockNumber(block.number);

    alice.setGame(game);
    albert.setGame(game);
    bob.setGame(game);
    barb.setGame(game);
    izzy.setGame(game);

    var participantReward = 10;
    var participantRewardCost = (participantReward * game.participants());
    transfer(alice, participantRewardCost, betAsset);
    alice.doApprove(game, betSize + participantRewardCost, betAsset);
    alice.doSetParticipantReward(participantReward);
    alice.doStartGame();

    // Commit
    albert.setBetHash(sha3(albertSalt, albertTarget));
    albert.doApprove(game, betSize, betAsset);
    albert.doJoinGame(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doJoinGame(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doJoinGame(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doJoinGame(izzy);

    // Advance the game past the commitment round
    game.setBlockNumber(block.number + game.commitmentBlocks());

    // Reveal
    alice.doRevealBet(aliceTarget, aliceSalt);
    albert.doRevealBet(albertTarget, albertSalt);
    bob.doRevealBet(bobTarget, bobSalt);
    barb.doRevealBet(barbTarget, barbSalt);
    izzy.doRevealBet(izzyTarget, izzySalt);

    // Advance the game past the reveal round
    game.setBlockNumber(block.number + game.commitmentBlocks() +
                       game.revealBlocks());


    // Advance the game past the claims round
    game.setBlockNumber(block.number + (game.commitmentBlocks() +
                       game.revealBlocks() + game.calculationBlocks()) * 2);

    // Request refunds
    alice.doRequestRefund();
    albert.doRequestRefund();
    bob.doRequestRefund();
    barb.doRequestRefund();
    izzy.doRequestRefund();

    // Check balances
    assertEq(alice.balanceIn(betAsset), betSize + participantReward);
    assertEq(albert.balanceIn(betAsset), betSize + participantReward);
    assertEq(bob.balanceIn(betAsset), betSize + participantReward);
    assertEq(barb.balanceIn(betAsset), betSize + participantReward);
    assertEq(izzy.balanceIn(betAsset), betSize + participantReward);
  }

  function testFailRefundsAfterCommitments () logs_gas {
    // Create & first commit
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    game.setBlockNumber(block.number);

    alice.setGame(game);
    albert.setGame(game);
    bob.setGame(game);
    barb.setGame(game);
    izzy.setGame(game);

    alice.doApprove(game, betSize, betAsset);
    alice.doStartGame();

    // Commit
    albert.setBetHash(sha3(albertSalt, albertTarget));
    albert.doApprove(game, betSize, betAsset);
    albert.doJoinGame(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doJoinGame(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doJoinGame(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doJoinGame(izzy);

    // Advance the game past the commitment round
    game.setBlockNumber(block.number + game.commitmentBlocks());

    // Request refunds
    alice.doRequestRefund();
    albert.doRequestRefund();
    bob.doRequestRefund();
    barb.doRequestRefund();
    izzy.doRequestRefund();
  }
}
