import 'dapple/test.sol';
import 'dappsys/token/base.sol';
import 'dappsys/token/registry.sol';
import 'makeruser/generic.sol';
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

  function doStartGame() {
    game.startGame(betHash, this);
  }

  function doApprove(address spender, uint value, bytes32 symbol) {
    approve(spender, value, symbol);
  }

  function doCommitBet(address recipient) {
    game.commitBet(betHash, recipient);
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

contract MockTokenRegistry is MakerTokenRegistry {
  function MockTokenRegistry () {
    set('BTC', bytes32(address(new DSTokenBase(21000000000000))));
    set('MKR', bytes32(address(new DSTokenBase(1000000 ether))));
  }

  function allocate(uint amount, bytes32 symbol, address recipient) {
    getToken(symbol).transfer(recipient, amount);
  }
}

contract MakerLobbyTest is Test {
  MockTokenRegistry registry;
  MakerDartsLobby lobby;
  MakerDartsActor alice;
  MakerDartsActor albert;
  MakerDartsActor bob;
  MakerDartsActor barb;
  MakerDartsActor izzy;

  bytes32 constant betAsset = 'BTC';
  uint constant betSize = 1000000;

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
    registry = new MockTokenRegistry();
    lobby = new MakerDartsLobby(registry);
    alice = new MakerDartsActor(registry, lobby);
    albert = new MakerDartsActor(registry, lobby);
    bob = new MakerDartsActor(registry, lobby);
    barb = new MakerDartsActor(registry, lobby);
    izzy = new MakerDartsActor(registry, lobby);

    registry.allocate(betSize, betAsset, alice);
    registry.allocate(betSize, betAsset, albert);
    registry.allocate(betSize, betAsset, bob);
    registry.allocate(betSize, betAsset, barb);
    registry.allocate(betSize, betAsset, izzy);
  }

  function testFailBetWithoutApproval () {
    bytes32 salt = 0xdeadbeef;
    bytes32 target = 0x7a26e7;
    alice.setBetHash(sha3(salt, target));

    alice.setGame(alice.createZSGame(1000000, 'BTC'));
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
    bob.doCommitBet(bob);
  }

  function testStartGame () logs_gas {
    // Create & first commit
    alice.setBetHash(sha3(aliceSalt, aliceTarget));

    var game = alice.createZSGame(betSize, betAsset);
    alice.setGame(game);
    alice.doApprove(game, betSize, betAsset);
    alice.doStartGame();
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
    albert.doCommitBet(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doCommitBet(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doCommitBet(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doCommitBet(izzy);

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
    albert.doCommitBet(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doCommitBet(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doCommitBet(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doCommitBet(izzy);

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
    albert.doCommitBet(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doCommitBet(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doCommitBet(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doCommitBet(izzy);

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

    alice.doApprove(game, betSize, betAsset);
    alice.doStartGame();

    // Commit
    albert.setBetHash(sha3(albertSalt, albertTarget));
    albert.doApprove(game, betSize, betAsset);
    albert.doCommitBet(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doCommitBet(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doCommitBet(barb);

    // Advance the game past the commitment round
    game.setBlockNumber(block.number + game.commitmentBlocks());

    // Request refunds
    alice.doRequestRefund();
    albert.doRequestRefund();
    bob.doRequestRefund();
    barb.doRequestRefund();

    // Check balances
    assertEq(alice.balanceIn(betAsset), betSize);
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

    alice.doApprove(game, betSize, betAsset);
    alice.doStartGame();

    // Commit
    albert.setBetHash(sha3(albertSalt, albertTarget));
    albert.doApprove(game, betSize, betAsset);
    albert.doCommitBet(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doCommitBet(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doCommitBet(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doCommitBet(izzy);

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
    assertEq(alice.balanceIn(betAsset), betSize);
    assertEq(albert.balanceIn(betAsset), betSize);
    assertEq(bob.balanceIn(betAsset), betSize);
    assertEq(barb.balanceIn(betAsset), betSize);
    assertEq(izzy.balanceIn(betAsset), betSize);
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
    albert.doCommitBet(albert);

    bob.setBetHash(sha3(bobSalt, bobTarget));
    bob.doApprove(game, betSize, betAsset);
    bob.doCommitBet(bob);

    barb.setBetHash(sha3(barbSalt, barbTarget));
    barb.doApprove(game, betSize, betAsset);
    barb.doCommitBet(barb);

    izzy.setBetHash(sha3(izzySalt, izzyTarget));
    izzy.doApprove(game, betSize, betAsset);
    izzy.doCommitBet(izzy);

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

