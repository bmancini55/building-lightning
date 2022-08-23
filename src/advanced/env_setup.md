# Environment Setup

The application code is available in the [Building on Lightning: Advanced](https://github.com/bmancini55/building-lightning-advanced) on GitHub. To get started, you can clone this repository:

```
git clone https://github.com/bmancini55/building-lightning-advanced.git
```

Navigate to the repository:

```
cd building-lightning-advanced
```

The repository uses `npm` scripts to perform common tasks. To install the dependencies, run:

```
npm install
```

Each section has scripts inside of the `exercises` directory.

We'll also need a Lightning Network environment to test. You can create a new Polar environment or reuse an existing one. Some of these exercises will require specific configurations of nodes and channels, so feel free to destroy and recreate environments as needed.

## Exercise: Configuring `.env` to Connect to LND

We'll again use the `dotenv` package to simplify environment variables.

You'll need to add some values to the `.env` inside the repository root. Specifically we'll set values for the following:

- `LND_RPC_HOST` is the host for LND RPC
- `LND_ADMIN_MACAROON_PATH` is the file path to the admin Macaroon
- `LND_CERT_PATH` is the certificate we use to securely connect with LND

To populate these values navigate to Polar. To access Alice's node by clicking on Alice and then click on the `Connect` tab. You will be shown the information on how to connect to the GRPC and REST interfaces. Additionally you will be given paths to the network certificates and macaroon files that we will need in `.env`.

![Connect to Alice](../images/ch1_polar_connect_to_alice.png)

Go ahead and add the three environment variables defined above to `.env`.

```
# LND configuration
LND_RPC_HOST=
LND_ADMIN_MACAROON_PATH=
LND_CERT_PATH=
```
