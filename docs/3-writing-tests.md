# Writing Tests

It's often been said that "if it isn't tested, it's broken." Writing software
for the blockchain is a particularly demanding exercise, so we're going to start
by writing a spate of tests for Maker Darts. I won't write down all of them
here; just enough to help you understand what's going on and get you on good
footing to begin writing tests for your own Ethereum projects.

First, let's make a `tests` directory in our `contracts` folder:

```
cd contracts
mkdir tests
```

All our Solidity code is going to live in the `contracts` directory, while all
our tests will live in `contracts/tests`. If you prefer using a different
directory for your Solidity code, you can change it in your project's dappfile.
The `sol_sources` setting in the `layout` mapping determines which directory
Dapple looks in for your Solidity code and to which directory all the imports in
your code will be relative.

Let's write our first test. All we want to do in this test is ensure Alice can
start a game and that the game created has all the properties she specified. So
first, let's create a file called `lobby.sol` in `contracts/tests`, and let's
start a test contract:

```
import 'dapple/test.sol';

contract MakerDartsLobbyTest is Test {

}
```

The line at the top of the file imports `test.sol` from the Dapple virtual
package automatically available in every Dapple package. This file defines a
smart contract called Test which every test must inherit from in order to get
run by the `dapple test` command. The Test contract supplies a few functions
relevant to testing, such as `assertTrue`, `assertFalse`, `assertEq`, the
`logs_gas` and `tests` modifiers, and others. The contract definition may be
found [on
Github](https://github.com/nexusdev/dapple/blob/master/constants/test.sol) at
the time of this writing.

The Test contract itself inherits from the Debug contract in `dapple/debug.sol`,
which provides many logging events which can be useful during the debugging
process. The contract definition for Debug is likewise [on
Github](https://github.com/nexusdev/dapple/blob/master/constants/debug.sol).

Now back to our test contract. We're going to need an "actor" contract to play
the parts of the various players, so let's write one that does what we want
Alice to be able to do in our current test:

```
contract LobbyActor {
  MakerDartsLobby lobby;

  function LobbyUser (MakerDartsLobby _lobby) {
    lobby = _lobby;
  }

  function createZSGame (uint bet, bytes32 asset, bytes32 hash)
      returns (MakerDartsGame) {
    return MakerDartsGame(_lobby.createZeroSumGame(bet, asset, hash));
  }
}
```

This contract allows us to call our MakerDartsLobby functions from various
addresses at will. Now let's plug it into our test:

```
contract MakerLobbyTest is Test {
  Lobby lobby;
  LobbyActor alice;

  function setUp() {
    lobby = new MakerDartsLobby();
    alice = new LobbyActor(lobby);
  }

  function testCreateZSGame ()
      tests("Alice's ability to create a zero-sum Maker asset game")
      logs_gas {
    bytes32 salt = 'this is a terrible salt';
    bytes32 target = bytes32(1);
    var betHash = sha3(salt + target);
    var game = alice.createZSGame(1000000, 'BTC', betHash);
    assertEq(game.participantReward(), 0);
    assertEq(game.betSize(), 1000000);
    assertTrue(game.tokenContract() != 0x0);
  }
}
```

The `logs_gas` and `tests` modifiers used with `testCreateZSGame` are optional
and included here for demonstration purposes only. `logs_gas` tells Dapple to
include the gas usage of the test case in its report, and `tests` tells Dapple
to include the given string alongside the test case in its report.

In this test, we simply create a lobby and an actor, then check the state of the
game created by `createZeroSumGame` to make sure it complies with our
expectations.

To test our new test:

```
dapple test
```

Our test will, of course, fail. None of the contracts referenced in our test
exist yet. Next we will proceed with defining them.
