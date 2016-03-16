# The Design

To begin exploring the problem in order to discover a good design for it in
code, let's summarize the game description from the introduction as a "golden
path" user story. The design goals here are to create a set of contracts that
can easily be hooked up to a Javascript-based GUI and which can potentially be
wrapped by other contracts, and to separate concerns so as to minimize
unnecessary side effects. E.g., creating games should be a constant cost
regardless of how many other games are currently running, and there should be no
cap on how many games can be running at any given time. Furthermore, the failure
of a game to complete should not in any way impede other games.

Given these design requirements, we may surmise a need for at least two
components: a game contract which represents a single game and a lobby contract
which may be used to create games and trigger UI events when games are created.

## Zero Sum Maker Darts

This is the ideal version of Maker Darts, as incentives are aligned so as to
provide a maximally random number. The trade-off is a possible lack of
participation if market forces favor fee-incentivized games.

1. Alice wishes to begin a game of Zero Sum Maker Darts using the Bitcoin token
contract deployed by Maker, a bet size of 10 mBTC (i.e., 0.01 BTC, or 1,000,000
satoshi), round lengths of 12 blocks apiece, and five players.

2. Alice calls `approve` on the Maker Bitcoin token contract, passing in the
number of satoshi she wishes to bet and the address of the Maker Darts lobby
contract.

3. Alice computes a random salt and picks a target number. She hashes them
together to obtain the value '0xf00b42'.

4. Alice calls `createZeroSumGame(1000000, 'BTC', '0xf00b42')` on the Maker
Darts lobby contract and receives back the address of a contract implementing
the MakerDartsGame interface. A `GamePending` event containing the newly
deployed game contract's address is emitted, allowing the UI to provide user
feedback and begin watching the new game contract for further events. Alice
accepts the default settings of no participant reward, 12-block rounds, and five
players, and calls `finalize()` on the MakerDartsGame, which locks the settings
in place and emits a `GameStarted` event from the game contract.

5. Bob wishes to join Alice's game. He calls `approve` on the Maker Bitcoin
token contract, passing in the integer 1000000 and the address of Alice's Maker
Darts game.

6. Bob creates and hashes his bet. He calls `joinGame` on Alice's MakerDartsGame
contract, passing it '0xf00dbab135', which is the hash of his bet. The game
emits a `Commit` event containing the sending address, the bet hash, and the
address making the bet. (This separation of the transaction sender from the
bettor address is necessary to allow other contracts to easily wrap this
contract and place bets on behalf of others.)

7. New players join during the commitment round, and the Maker Darts game emits
`Commit` events for each one. Our frontend developer can surmise when the game
is full once the number of Commit events with unique bet hashes is equal to the
game's `participants` property.

8. Once the block height at which the revealing round begins is reached, each
player calls `reveal`, passing in their salt and their target number. The game
emits `Reveal` events for each one.

9. All players call `calculateResult()` on the game contract after the revealing
round has ended. This returns a unique random number for each player and emits
it, along with how close their target number was to their random number result,
via the `Result` event. After this, the player may pass their bet's commit hash
to `getResult` to retrieve their random number without having to re-calculate
it. They may do the same with the `getDistance` function to get the XOR of their
target number with their random number.

10. Once the block at which the calculation round has ended is reached, players
call the `claimPayment()` function to claim half their bet back, plus any
fees and winnings. `Claim` events are emitted each time.

11. Once the payment claims round has ended, anyone may call `destroy` on the
game contract to remove it from the blockchain.

This golden path user story is a good start, but normally we would want to flesh
out a number of other user stories as well. Ideally we would cover as many types
of interaction as possible. This is part of the discovery process, as it forces
us to think about the system's design deeply and helps us find potential failure
modes and unexpected use cases. For the sake of keeping this guide brief,
however, I'm only publishing this single user story.

## Components

As mentioned before, two primary components jump out: a Maker Darts lobby
contract and a Maker Darts game contract. There is also an implicit Maker Asset
Registry component, of course, but this is not a component we will have to
implement ourselves.

## Edge Cases

As we design and develop this system, we'll want to keep track of edge cases:
failure modes owing to unusual (but inevitable) circumstances. For example, a
game with too many participants may fail at a late stage due to gas costs.
Generally, many edge cases can be discovered by separating out the various
variables in a system and asking ourselves what happens when they're set to the
maximum and minimum values allowed by their datatypes. And if their datatypes
allow over/underflows or other dangerous mutations, what happens in those
circumstances as well?

Each edge case should be expressed as an automated test in a clearly demarcated
location, both to ensure that the behavior of the system under those
extraordinary circumstances is as expected and to also provide documentation of
how each circumstance is handled. If our system's edge cases are not called out
anywhere, then each person building on our system will have to rediscover them
for themselves, and they may end up missing a few critical ones. Well-written
automated tests constitute documentation that are nearly as reliable as the
actual code, and they are generally better at conveying intent to boot.
