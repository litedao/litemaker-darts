# Writing Contracts

We want to let users use any ERC20 token contracts registered in the
Maker-curated token contract registry. The token registry, in our case, acts as
a whitelist for token contracts and helps prevent incoming capital from becoming
needlessly fragmented across too many token contracts. The MakerUser library
introduced in the previous section helps with this by providing ERC20-like
functions to any inheriting contracts.

There were two primary components we identified earlier: a game contract and a
lobby contract, which acts as a sort of factory for the game contract. Given
that we are following TDD methodology here, our only goal in this section will
be to pass the test we wrote in the previous section. Development beyond this
point is left as an exercise for the reader, as the purpose of this guide is to
demonstrate a set of tools and a methodology for writing dapps.

First we will write our game contract. To pass our test it needs to have betAsset,
betSize, and participantReward properties. Create a file called game.sol in the
contracts directory with these contents:

```
contract MakerDartsGame {
  uint public betSize;
  bytes32 public betAsset;
  uint public participantReward;

  function MakerDartsGame(uint _betSize, _betAsset) {
    betSize = _betSize;
    betAsset = _betAsset;
  }

  function setParticipantReward(uint reward) {
    participantReward = reward;
  }
}
```

In the above code we create a contract type that has the properties necessary to
pass its test. The betSize and betAsset properties are public, which means
Solidity will automatically create getter functions for them. I have also opted
to require passing in betSize and betAsset to the constructor, since those are
mandatory values and must be set, while having participantReward only get set if
its setter function gets called.

Now for the lobby contract. Create a file named lobby.sol in the contracts
directory with the following contents:

```
import 'game.sol';

contract MakerDarts is MakerUserGeneric {
  function MakerDartsLobby (MakerTokenRegistry registry)
           MakerUserGeneric (registry) {}

  function createZeroSumGame (uint betSize, bytes32 betAsset)
      returns (address) {
    return new MakerDartsGame(betSize, betAsset);
  }
}
```

The final step to getting our (very simple) test to pass should be simply
importing our new files. Add this to the top of the
contracts/tests/lobby.sol file, below the other import statements:

```
import 'lobby.sol';
```

Now running `dapple test` should result in our test passing. Completing the rest
of the game is now just a matter of iterating on this process. It can take
discipline to stick to this approach, but in the end it pays off in reduced
development complexity and cleaner, safer code.

This is as far into writing the code as I plan on going. Those of you who are
curious about how I solved the remainder of the problem can find the finished
code for this project can be found [on
Github](https://github.com/MakerDAO/maker-darts). Next I will cover deploying
the lobby to the blockchain using Dapple's Deploy Script language. (Don't worry:
it's a very simple language designed to make deployment much easier than it
would otherwise be!)
