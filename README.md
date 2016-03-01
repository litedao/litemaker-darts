# Maker Darts

Maker Darts is a RANDAO implementation for Ethereum. Randomization is
provided by participants who themselves desire a trustworthy random number.
Participants are furthermore incentivized to provide unpredictable input, as
any observable patterns may be leveraged by other players to obtain
better-than-random odds.

# How it works

A game is initiated when a user posts a bet of arbitrary size, a hash of a salt
value plus a target value, the minimum number of other participants they desire,
the winner's reward (an integer percentage of the losers' bets the winners may
claim), the number of winners this game, the lengths in blocks of the
commitment, revelation, and tabulation rounds, and the symbol of the token being
used for placing bets. They may also optionally offer a fee to incentivize
participants with lower risk tolerance to join. (It is not recommended that the
fee exceed half the size of the bet, as this attenuates the incentive
participants have to provide unpredictable input.)

To join a game, a prospective participant must post a bet equal to the bet of
the person who created the game, a hash of a salt value plus a target value, and
the ID of the game they wish to join.

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
