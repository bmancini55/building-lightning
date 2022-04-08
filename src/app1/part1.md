# Environment Setup

We'll start by setting up your environment. Since we're going to build a Lightning Network application it should not be surprising that our infrastructure consists of a Bitcoin node and one or more Lightning Network nodes that we can control.

As a user of Bitcoin and the Lightning Network you are most likely familiar with the main Bitcoin network. Bitcoin software actually has multiple networks that it can run on:

- mainnet - primary public network; the network a user interacts with.
- testnet - alternate network used for testing. It is typically smaller in size and has some other properties that make it useful for testing software built on top of Bitcoin. [More info](https://en.bitcoin.it/wiki/Testnet).
- regtest - regression testing network that gives us full control of block creation.

For creating and testing our Lightning Network applications we'll want our infrastructure to start with the regtest network to give us control and speed up our development process. At a future time we can transition to running in testnet or mainnet.

As you can imagine, getting all this running can be a chore. Fortunately, there is the tool [Polar](https://lightningpolar.com) that allows us to spin up Lightning network testing environments easily!

Our first step is to download and install Polar for your operating system from the [website](https://lightningpolar.com).

For a Linux system, it will be as an AppImage. You will need to grant executable rights to the file, then you can run the application.

For Mac it will be a .dmg file that you will need to install.

For Windows, it will be an .exe file that you can run.

Once Polar is running, you can create a new network. Polar allows us to run many different networks with varying configurations. For this application we will start the network with 1 LND node, 1 c-lightning node, 1 Eclair, and 1 Bitcoin Core node. Provide a name for this network and create it!

![Polar Network](/images/ch1_polar_create.png)

Next, start the network. Polar will launch Docker containers for each of the nodes in your network. This may take a few minutes for the nodes to come online.

Polar also provides a few tools to allow us to easily perform common tasks.

We will start by depositing some funds into Alice's node. To do this, click on Alice's node, then click on the `Actions` tab.

We will then deposit 1,000,000 satoshis into Alice's node. When you click the `Deposit` button, the Bitcoin Core node running in regtest will create new blocks to an address and 0.01000000 bitcoin (1,000,000 satoshis) will deposited into an address controlled by Alice's Lightning Network node.

![Alice with 1mil Sats](/images/ch1_polar_deposit.png)

Now that Alice has some funds, she can create a channel with another node on the network. We can do this by opening an outgoing channel by clicking the `Outgoing` button in the `Open Channel` section of Alice's Actions tab.

Let's choose Bob as the channel counterparty and fund the channel with 250,000 satoshis.

![Alice to Bob Create Channel](/images/ch1_polar_open_channel.png)

We should now see a channel link between Alice and Bob in our channel graph.

![Alice to Bob Channel](/images/ch1_polar_alice_bob.png)

At this point, we are ready to write some code!
