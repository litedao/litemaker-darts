# Deploying and Publishing

We have written our simple RNG DAO and now it's time to deploy. In this section
I'll take you through deploying our DAO with Dapple and publishing it to Dapphub
so other people can begin building on top of it and incorporating it into their
own projects.

Dapple deploy scripts by convention are kept in a `deploy` directory and given
the .ds file extension. In this section we are going to create a simple deploy
script for deploying MakerDarts to the test network (which is presently named
Morden), hence we'll create our script at deploy/morden.ds. I'll also go into
some of the language features we won't be using, just to help you in using the
deploy script for other projects.  After all, the deploy script for MakerDarts
is very simple indeed. In fact, it's just these two lines:

```
var lobby = new MakerDartsLobby('0x213183be469a38e99facc2c468bb7e3c01377bce')
export lobby
```

So what do these two lines do? You can probably surmise what the first one does:
it deploys a new MakerDartsLobby contract, passing it the address of the Maker
Asset Registry and saving the deployed contract to the lobby variable. The
second line simply maps the variable's name, `lobby`, to the deployed contract's
address in the `objects` mapping for whatever environment the script is run
against in the project's dappfile.

That was quite the run-on sentence, so here's an example:

```
$ dapple run deploy/morden.ds -e morden
$ cat dappfile
name: makerdarts
version: 0.1.0
layout:
  sol_sources: contracts
  build_dir: build
dependencies:
  makeruser: 0.1.0
environments:
  morden:
    objects:
      lobby:
        class: MakerDartsLobby
        address: '0xdeadbeef'
```

This of course assumes you have set up a `morden` environment in your
~/.dapplerc file.

We will also want to deploy to livenet before publishing, of course. For the
sake of brevity, let's assume we've done that. Now all that's left is publishing
to dapphub:

```
$ dapple publish -e live
```

Since Dapple uses an on-chain contract to map package names and versions to IPFS
hashes, we need to specify an environment to deploy to as in the example above.
Now that we've done so, other packages may install our package as a dependency
using `dapple install`:

```
$ dapple install makerdarts 0.1.0
```

That concludes the process of creating and publishing a simple contract system.
If our contract system had been a bit more complex, we might have needed a few
of the deploy script's language features. For example, it's possible to
synchronously call any function defined on a contract, specifying both gas and
value parameters:

```
lobby.createZSGame.gas(3141592).value(1)()
```

You can also interact with contracts already deployed to the blockchain:

```
var MAR = MakerTokenRegistry('0x213183be469a38e99facc2c468bb7e3c01377bce')
log DSToken(MAR.getToken('MKR')).totalSupply()
```

Notice also the `log` statement in the above script. Arbitrary values may be
logged to the console during script execution using the `log` statement. The
script above gets the MKR token contract from the Maker Asset Registry and logs
its total supply to the command line. If we wanted to turn this into a sanity
check, we could have used the `assert` statement instead:

```
var MAR = MakerTokenRegistry('0x213183be469a38e99facc2c468bb7e3c01377bce')
// Make sure we have one million MKR with eighteen decimal places.
assert DSToken(MAR.getToken('MKR')).totalSupply() == 1000000000000000000000000;
```

The above script would halt execution immediately if the boolean value passed to
`assert` were incorrect. Note also that the scripting language supports single
line comments via `//`.

This is not an exhaustive tour of the deploy scripting language, but it covers
most of its functionality. If you are comfortable with reading Bison language
definitions, the full language definition can be found [on
Github](https://github.com/nexusdev/dapple/blob/master/specs/dsl.y).

This has been a brief, but hopefully enlightening, look at the process I use to
build smart contract systems. If you have any questions or comments, please feel
free to leave a comment or [tweet at me](https://twitter.com/ryepdx).
