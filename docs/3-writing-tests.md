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
import 'makeruser/user_test.sol';

contract MakerDartsLobbyTest is MakerUserTest {

}
```

The line at the top of the file imports `user_test.sol` from the MakerUser
package. This file defines a contract named MakerUserTest which inherits from
the Test contract defined in the Dapple virtual package automatically available
in every Dapple package. Every test must inherit either directly or indirectly
from Test in order to get run by the `dapple test` command. The Test contract
supplies a few functions relevant to testing, such as `assertTrue`,
`assertFalse`, `assertEq`, the `logs_gas` and `tests` modifiers, and others. The
contract definition may be found [on
Github](https://github.com/nexusdev/dapple/blob/master/constants/test.sol) at
the time of this writing.

The Test contract itself inherits from the Debug contract in `dapple/debug.sol`,
which provides many logging events which can be useful during the debugging
process. The contract definition for Debug is likewise [on
Github](https://github.com/nexusdev/dapple/blob/master/constants/debug.sol).

The MakerUserTest contract gets us a mock token registry contract for free via
its `setUp` function. We can interact with the mock token registry using the
same functions available to us in any contract inheriting from MakerUser, such
as `getBalance`, `transfer`, `transferFrom`, `allowance`, and `approve`. The
`setUp` function also allocates balances of 1,000,000 of the smallest units
of MKR, ETH, and DAI to our test contract.

Now back to our test contract. We're going to need an "actor" contract to play
the parts of the various players, so let's write one that does what we want
Alice to be able to do in our current test:

```
contract MakerDartsActor is MakerUserTester {
  MakerDartsLobby lobby;

  function MakerDartsActor (MakerTokenRegistry registry,
                            MakerDartsLobby _lobby)
           MakerUserTester (registry) {
    lobby = _lobby;
  }

  function createZSGame (uint bet, bytes32 asset)
      returns (MakerDartsGame) {
    return MakerDartsGame(_lobby.createZeroSumGame(bet, asset));
  }
}
```

This contract allows us to call our MakerDartsLobby functions from various
addresses at will, simulating multiple users interacting with it. Now let's plug
it into our test:

```
contract MakerLobbyTest is MakerUserTest {
  MakerDartsLobby lobby;
  MakerDartsActor alice;

  bytes32 constant betAsset = 'DAI';
  uint constant betSize = 1000;

  function setUp() {
    MakerUserTest.setUp(); // call parent function
    lobby = new MakerDartsLobby(_M); // _M is the token registry
    alice = new MakerDartsActor(_M, lobby);
    transfer(alice, betSize, betAsset); // give Alice some dai to play with
  }

  function testCreateZSGame ()
      tests("Alice's ability to create a zero-sum Maker asset game")
      logs_gas {
    var game = alice.createZSGame(betSize, betAsset);
    assertEq(game.participantReward(), 0); // default setting
    assertEq(game.betSize(), betSize);
    assertEq32(game.betAsset(), betAsset); // assertEq32 is assertEq for bytes32
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
exist yet. If you aren't used to test driven development, this is the general
flow TDD practitioners attempt to follow. While it may seem obvious that the
test would fail in this case, it's always a good idea to test one's assumptions,
even if they seem to be fairly obvious. If our test *didn't* fail, that would be
very interesting and would indicate a broken test whose passing cannot be
trusted! The first thing a test tests is itself: it demonstrates its correctness
by failing.

Next we'll write minimal implementations of our contracts and get our test
passing.
