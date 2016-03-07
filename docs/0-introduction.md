# Maker Darts

## Introduction

About a week ago, I came up with a idea for random number generation that was
very similar to what [the RANDAO project](https://github.com/randao/randao) is
doing. I was at the time unaware of their efforts, though, and ended up using a
slightly different approach. In short, both Maker Darts (as I am calling this
project) and RANDAO generate random numbers by hashing user input in sequence. I
will get into the specifics of my model later, but for now let me highlight the
three places where we diverged and why I made the design decisions I did.

First of all, Maker Darts allows for the creation of zero-sum games that may
nonetheless result in the generation of random numbers for no cost (aside from
Ethereum network transaction fees) in the long run due to the fact that all
players have even odds of winning as long as all players are equally
unpredictable in their input. If other players are predictable, a canny player
may limit the search space for their prediction based on the range of probable
inputs from the other players and thus profit by winning with
better-than-average odds. Thus players have an incentive to provide
unpredictable input to the RNG.

Second, bets are sorted according to a pre-determined algorithm before the
revealing begins. My goal here is to reduce any potential risk that might be
associated with the miner's ability to re-arrange transaction execution order.
I admit that there are no concrete attack vectors that immediately spring to
mind, but the precaution does further reduce the role miner choice plays in the
eventual outcome of the game. Whether this precaution is worth the extra
transaction costs remains to be seen at this point. (I'll demonstrate how to
make this judgement later in this series.)

Third, players may use any asset listed in the Maker Asset Registry, including
ether. This increases market choice while also providing an extra degree of
safety via a whitelist.

## Gameplay

A game is initiated when a user posts a bet of arbitrary size, a hash of a salt
value plus a target value, the minimum number of other participants they desire,
the winner's reward (an integer percentage of the losers' bets the winners may
claim), the number of winners this game, the lengths in blocks of the
commitment, revelation, and tabulation rounds, and the symbol of an asset in the
Maker Asset Registry. They may also optionally offer a fee to incentivize
participants with lower risk tolerance to join. (It is not recommended that the
fee exceed half the size of the bet, as this attenuates the incentive
participants have to provide unpredictable input.)

To join a game, a prospective participant must post a bet equal to the bet of
the person who created the game, a hash of a salt value plus a target value, and
the ID of the game they wish to join. This is done via two transactions: first
to the `approve` function of the token contract being used in the game to grant
the game the ability to charge a number of tokens equal to the bet size, and
then to the game's `commit` function to supply it with the player's bet and
allow the game to charge the player's token contract account.

New participants may only join during the commitment round. If the commitment
round ends without enough participants joining, the round is cancelled and
participants may request refunds.

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
failed to reveal. The function also distributes participation fees to each
player. Participants have a number of blocks equal to the sum of the commitment,
revelation, and tabulation round lengths to call this function. Any bets and
fees not collected during this time are lost forever.
