# The Design

To begin exploring the problem in order to discover its optimal design, let's
summarize the game description from the introduction as a "golden path" user
story.

## Zero Sum Maker Darts

This is the ideal version of Maker Darts, as incentives are aligned so as to
provide a maximally random number. The trade-off is a possible lack of
participation if market forces favor fee-incentivized games.

1. Alice wishes to begin a game of Zero Sum Maker Darts using the Bitcoin token
contract deployed by Maker, a bet size of 10 mBTC (i.e., 0.01 BTC, or 1,000,000
satoshi), round lengths of 12 blocks apiece, and five players.

2. Alice calls `approve` on the Maker Bitcoin token contract, passing in the
number of satoshi she wishes to bet and the address of the Maker Darts contract.

3. Alice computes a random salt and picks a target number. She adds and then
hashes them together to obtain the value '0xf00b42'.

4. Alice calls `createZeroSumMARGame(1000000, 'BTC', '0xf00b42')` on the Maker
Darts contract and receives back the address of a contract implementing the
MakerDartsGame interface. She accepts the default settings of no participant
reward, 12-block rounds, and five players, and calls `finalize()` on the
MakerDartsGame, which locks the settings in place, lists the game in the
Maker Darts contract as available for players to join, and emits a `NewGame`
event.

5. Bob wishes to join Alice's game. He calls `approve` on the Maker Bitcoin
token contract, passing in the integer 1000000 and the address of Alice's Maker
Darts game.

6. Bob creates and hashes his bet. He calls `joinGame` on Alice's MakerDartsGame
contract, passing it '0xf00dbab135', which is the hash of his bet. The game
emits a `Commitment` event.

7. New players join during the commitment round, and the Maker Darts game emits
`PlayerJoined` events for each one, as well as a `GameFull` event once enough
players have committed.

8. Once the block height at which the revealing round begins is reached, each
player calls `reveal`, passing in their salt and their target number. The game
emits `BetRevealed` events for each one, as well as an `AllRevealed` event once
all players have revealed their bets.

9. All players call `calculateRandomNumber()` on the game contract after the
`reveal` round has ended. This returns a unique random number for each player
and emits it via the `RandomNumber` event. After this, the player may call
`getRandomNumber()` to retrieve their random number without having to
re-calculate it.

10. Once the block at which the calculation round has ended is reached, players
call the `claimPayment()` function to claim half their bet back, plus any
fees and winnings. `PaymentClaimed` events are emitted each time.

11. Once the payment claims round has ended, anyone may call `destroy` on the
game contract to remove it from the blockchain.

This golden path user story is a good start, but normally we would want to flesh
out a number of other user stories as well. Ideally we would cover as many types
of interaction as possible. This is part of the discovery process, as it forces
us to think about the system's design deeply and helps us find potential failure
modes and unexpected use cases. For the sake of keeping this guide brief,
however, I'm only publishing this single user story.

## Components

Given the above story, two primary components jump out: a Maker Darts lobby
contract and a Maker Darts game contract. This division of parts makes sense to
me because it ensures that failure in any single game due to poorly-considered
parameters (e.g., setting "number of participants" to a high enough value as to
cause `calculateRandomNumber` to always run out of gas) has no effect on other
games, or on the ability of the players to make another game.

There is also an implicit Maker Asset Registry component, of course, but this is
not a component we will have to implement ourselves.

## Edge Cases

As we design and develop this system, we'll want to keep track of edge cases:
failure modes owing to unusual (but inevitable) circumstances. We've already
noted one above: any game with too many participants may fail at a late stage
due to gas costs. Generally, many edge cases can be discovered by separating out
the various variables in a system and asking ourselves what happens when they're
set to the maximum and minimum values allowed by their datatypes. And if their
datatypes allow over/underflows or other dangerous mutations, what happens in
those circumstances as well?

Each edge case should be expressed as an automated test in a clearly demarcated
location, both to ensure that the behavior of the system under those
extraordinary circumstances is as expected and to also provide documentation of
how each circumstance is handled. If our system's edge cases are not called out
anywhere, then each person building on our system will have to rediscover them
for themselves, and they may end up missing a few critical ones. Well-written
automated tests constitute documentation that are nearly as reliable as the
actual code, and they are generally better at conveying intent.
