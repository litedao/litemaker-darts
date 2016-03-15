# Maker Darts

## Introduction

A few weeks ago, I came up with a idea for random number generation that was
very similar to what [the RANDAO project](https://github.com/randao/randao) is
doing. I was at the time unaware of their efforts, though, and ended up using a
slightly different approach. In short, both Maker Darts (as I am calling this
project) and RANDAO generate random numbers by hashing user input together. I
will get into the specifics of my model later, but for now let me highlight the
two places where we diverged and why I made the design decisions I did.

First of all, Maker Darts allows for (but does not mandate) the creation of
zero-sum games that may nonetheless result in the generation of random numbers
for no cost (aside from Ethereum network transaction fees) in the long run due
to the fact that all players have even odds of winning as long as all players
are equally unpredictable in their input. If other players are predictable, a
canny player may limit the search space for their bet based on the range of
probable inputs from the other players and thus profit by winning with
better-than-average odds.  Thus players have an incentive to provide
unpredictable input to the RNG.

Second, players may use any asset listed in the Maker Asset Registry, including
ether. This increases market choice while also providing an extra degree of
safety via a whitelist. This constraint also helps keep the available liquidity
from getting spread too thinly across too many asset types.

## Gameplay

A game is initiated when a user posts a bet of arbitrary size, a hash of a salt
value plus a target value, the minimum number of other participants they desire,
the winner's reward (an integer percentage of the losers' bets the winners may
claim), the number of winners this game, the lengths in blocks of the
commitment, revelation, and tabulation rounds, and the symbol of an asset in the
Maker Asset Registry. They may also optionally offer a fee to incentivize
participants with lower risk tolerance to join. (It is not recommended that the
fee exceed half the size of the bet, as this may greatly attenuate the incentive
participants have to provide unpredictable input.)

After creating a game contract, the owner may adjust the game's parameters via
various functions. Once everything is set up according to the owner's wishes,
they may begin the commitment round by calling `startGame`. The `startGame`
function works in much the same way as the `joinGame` function described below.
That is to say, it requires first approving the game contract for a debit from
the owner's account in the token contract large enough to cover the bet size
plus the participant reward.

To join a game, a prospective participant must at minimum post a bet equal to
the bet of the person who created the game and a hash of a salt value plus a
target value. This is done via two transactions: first to the `approve` function
of the token contract being used in the game to grant the game the ability to
charge a number of tokens equal to the bet size, and then to the game's
`joinGame` function to supply it with the player's bet and allow the game to
charge the player's token contract account.

New participants may only join during the commitment round. If the commitment
round ends without enough participants joining, the round is cancelled and
participants may request refunds. Participants are not given a participant
reward in this case.

Once the commitment round ends, the revelation round begins. During this round,
participants submit their salts and target values. Following this, each
participant calls a function to calculate their random number. Each random
number consists of the salts and targets of every other participant sha3'ed
together in order of commitment hash, with the salt and target of the calling
participant transposed to the beginning of the list.

Though at this point each participant has received a unique random number from
the DAO, the smart contract still holds the participants' bets. At this point,
the half of the participants whose chosen targets end up furthest from their
random numbers may call a function to reclaim half their bet. The half closest
to their targets call the same function to reclaim their original bet plus half,
as well as the bets of users who submitted commitment transactions but then
failed to reveal. The function also distributes participation rewards to each
player. Participants have a number of blocks equal to the sum of the commitment,
revelation, and tabulation round lengths to call this function. Any bets and
rewards not collected during this time are lost forever.

If nobody can claim their rewards and fees, as would be the case if the owner
created a game with too many participants, then participants may request refunds
of their bets plus payout of the participant reward via the `requestRefund`
function. Thus game owners offering participant rewards are incentivized to only
offer games that may be completed by participants given whatever the prevailing
block gas limit is at the time.
