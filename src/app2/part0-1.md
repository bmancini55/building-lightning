# Environment Setup

Before we get started with invoices we first need to get our environment setup again. This application uses the same template we used in the Graph exercise, so you should already be familiar with the structure. For this application we'll only be focusing on building logic inside the `server` sub-project.

The application code is available in the [Building on Lightning Invoices Project](https://github.com/bmancini55/building-lightning-invoices) on GitHub. To get started, you can clone this repository:

```
git clone https://github.com/bmancini55/building-lightning-invoices.git
```

Navigate to the repository:

```
cd building-lightning-invoices
```

The repository uses `npm` scripts to perform common tasks. To install the dependencies, run:

```
npm install
```

This will install all of the dependencies for the three sub-modules in the project: `client`, `server`, and `style`. You may get some warnings, but as long as the install command has exit code 0 for all three sub-projects you should be good. If you do encounter any errors, you can try browsing to the individual sub-project and running the `npm install` command inside each directory.

We'll also need a Lightning Network environment to test. You can use the existing environment you created with Polar in the first project.

We'll again be building the application from the perspective of Alice using an LND node.

## Exercise: Configuring `.env` to Connect to LND

We'll again use the `dotenv` package to simplify environment variables.

You'll need to add some values to the `.env` inside the `server` sub-project. Specifically we'll set values for the following:

- `LND_RPC_HOST` is the host for LND RPC
- `LND_ADMIN_MACAROON_PATH` is the file path to the admin Macaroon
- `LND_INVOICE_MACAROON_PATH` is the file path to the invoice Macaroon
- `LND_READONLY_MACAROON_PATH` is the file path to the "readonly" Macaroon
- `LND_CERT_PATH` is the certificate we use to securely connect with LND

Optionally, you can also set the `LND_REST_HOST` value.
It's not necessary for this tutorial, but if you want to experiment with the REST API via the `building-lightning-invoices` repo, you will need it.

To populate these values navigate to Polar. To access Alice's node by clicking on Alice and then click on the `Connect` tab. You will be shown the information on how to connect to the GRPC and REST interfaces. Additionally you will be given paths to the network certificates and macaroon files that we will need in `.env`.

![Connect to Alice](../images/ch1_polar_connect_to_alice.png)

Go ahead and add the environment variables defined above to `.env`.

```
# Express configuration
PORT=8001

# LND configuration
# Exercise: Provide values for Alice's node
LND_REST_HOST=
LND_RPC_HOST=
LND_CERT_PATH=
LND_ADMIN_MACAROON_PATH=
LND_INVOICE_MACAROON_PATH=
LND_READONLY_MACAROON_PATH=
```
