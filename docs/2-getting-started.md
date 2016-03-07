# Getting Started

Now that we've got a decent idea of what we want to build, it's time to start
building. Before we begin, though, please be aware that I've written this guide
for Linux machines, as that's what I've been using almost exclusively for
the past seven years now. OS X users should have no trouble following along due
to the high degree of overlap it has with Linux systems. The initial setup
process might be tricky for Windows users, though. If you reach the end of your
rope wrangling with PowerShell, you might find [the Ubuntu-based Docker
image](https://hub.docker.com/r/ryepdx/nexus_dev/) I created for CLI-centric
Ethereum dapp development useful.

First thing we're going to do is create a directory for our project and get it
under [version control](https://git-scm.com/). If you don't have git installed,
I recommend installing it generally, as it gets used quite a lot in open source
these days, and you'll find it very useful if you plan on getting delving deeper
into Ethereum development. Otherwise, it's not strictly necessary, though it
could save you some headaches down the road.

Fire up a command line (Terminal, for you OS X users) and type:

```
mkdir maker-darts
cd maker-darts
git init
```

You *are* going to need [NodeJS](https://nodejs.org/en/), though. I recommend
version 5.1.1 or higher. Once you have NodeJS installed, you'll want to install
[the Dapple Ethereum package manager](https://www.npmjs.com/package/dapple).

```
npm install -g dapple
```

Dapple does a few nice things for us, chief among which is managing our
[Solidity](https://solidity.readthedocs.org/) packages and running tests. We
want to turn our maker-darts directory into a Dapple package now so we can use
its features.

```
dapple init
```

Dapple relies on a combination of IPFS and the Ethereum blockchain for low-trust
package publishing and installation. While it is entirely possible for an author
to publish a malicious Dapple package, IPFS removes the need to trust a central
package hosting server to serve correct, unaltered code, and the Ethereum
blockchain ensures a reliable mapping is maintained between IPFS hashes and
package names and versions. If you don't already have an Ethereum client such as
[geth](https://ethereum.org/#install-geth), you'll want to install that now.
And you'll also want [IPFS](https://ipfs.io). These are tools that have become
generally common among Ethereum developers, so you'll probably find them
cropping up again and again as you dig into this space.

Again, if you have trouble getting things set up, you can try [the Docker
image](https://hub.docker.com/r/ryepdx/nexus_dev/) mentioned earlier. It comes
with geth and IPFS already installed.

To run the IPFS server, open another terminal and enter:

```
ipfs daemon
```

You'll want to run geth with the `--rpc` flag set. If you plan on publishing
packages to DappHub or deploying to the blockchain, you'll also want to set the
coinbase to the account you want to publish from and you'll need to have it
unlocked. All together:

```
geth --rpc --etherbase <your account> --unlock <your account>
```

Be careful, though: running geth with an unlocked account makes the ether in
that account more vulnerable to theft. Keep only a minimal amount of ether in
whatever account you choose to publish from in order to limit your risk.

If you choose to connect to IPFS or geth via a remote server, or if you
choose to run IPFS or geth on a different port than the defaults, you'll want to
edit the `.dapplerc` file Dapple creates in your home directory on its first
run. The settings should be fairly self-explanatory.

Regardless, we'll want to change our package's name from the default Dapple
gives us. So we'll open `dappfile` in our project directory and change the line
that reads `name: "mypackage"` to `name: makerdarts`. We'll also be relying on
the MakerUser Dapple package for our token handling, so let's install that now
and add it as a dependency to our dappfile:

```
dapple install --save makeruser 0.1.0
```

The above command retrieves the IPFS hash of version 0.1.0 of the MakerUser
package from the DappHub database smart contract on the Ethereum blockchain,
then pulls the package down from IPFS into our `dapple_packages` directory, and
then finally adds the line `makeruser: 0.1.0` to the dependencies list in our
dappfile.

Now that we have everything installed and configured, we will next begin
defining our system in code by writing some tests.
