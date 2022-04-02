# Visualizing the Lightning Graph

Welcome to Building on Lightning! This series will acquaint you with tools and techniques you will need to build Lightning Network applications. The first application we will build is a visualizer of Lightning Network nodes and channels. The end result is that our application will have an interface that queries a Lightning Network node and receives real-time updates from that node.

This project uses [TypeScript](https://www.typescriptlang.org/) in the [Node.js](https://nodejs.org/en/) runtime. If you're not familiar with TypeScript, I suggest you do a tutorial to help you understand the code in this tutorial. Node.js is a popular runtime for web development. When combined with TypeScript it allows us to build large applications with compile-time type checking. This helps us reduce mistakes and properly structure our applications for future changes and developers.

This project also uses [Express](https://expressjs.com) as the web framework. It is a fast, easy to use, and popular web framework. Lastly this project uses [React](https://reactjs.org/) and [D3](https://d3js.org/) for creating the visualization of the Lightning Network graph.

## Development Environment

We'll get started by setting up your infrastructure and development environment. Since we're going to build a Lightning Network application it should not be surprising that our infrastructure consists of a Bitcoin node and one or more Lightning Network nodes that we can control.

As a user of Bitcoin and the Lightning Network you are most likely familiar with the main Bitcoin network. Bitcoin software actually has multiple networks that it can run on:

- mainnet - primary public network; the network a user interacts with.
- testnet - alternate network used for testing. It is typically smaller in size and has some other properties that make it useful for testing software built on top of Bitcoin. [More info](https://en.bitcoin.it/wiki/Testnet).
- regtest - regression testing network that gives us full control of block creation.

For creating and testing our Lightning Network applications we'll want our infrastructure to start with the regtest network to give us control and speed up our development process. At a future time we can transition to running in testnet or mainnet.

As you can imagine, getting all this running can be a chore. Fortunately, there is the tool [Polar](https://lightningpolar.com) that allows us to spin up Lightning network testing environments easily!

Our first step is to download and install Polar for your operating system from the [website](https://lightningpolar.com).

For a Linux system, it will be as an AppImage. You will need to grant executable rights to the file, then you can run the application.

Once Polar is running, you can create a new network. Polar allows us to run many different networks with varying configurations. For this application we will start the network with 1 LND node, 1 c-lightning node, 1 Eclair, and 1 Bitcoin Core node. Provide a name for this network.

![Polar Network](images/ch1_polar_create.png)

Start the network once it has been created. Polar will launch Docker containers for each of the nodes in your network.

Polar also provides a few tools to allow us to easily perform common tasks.

We will start by depositing some funds into Alice's node. To do this, click on Alice's node, then click on the `Actions` tab.

We will then deposit 1,000,000 satoshis into Alice's node. When you click the `Deposit` button, the Bitcoin Core node running in regtest will create new blocks to an address and 0.01000000 bitcoin (1,000,000 satoshis) will deposited into an address controlled by Alice's Lightning Network node.

![Alice with 1mil Sats](images/ch1_polar_deposit.png)

Now that Alice has some funds, she can create a channel with another node on the network. We can do this by opening an outgoing channel by clicking the `Outgoing` button in the `Open Channel` section of Alice's Actions tab.

Let's choose Bob as the channel counterparty and fund the channel with 250,000 satoshis.

![Alice to Bob Create Channel](images/ch1_polar_open_channel.png)

We should now see a channel link between Alice and Bob in our channel graph.

![Alice to Bob Channel](images/ch1_polar_alice_bob.png)

At this point, we are ready to connect to Alice's node via the API.

### Connecting to Alice's node

vvvvvvvvvvvvvvvvvvvvvvvvvvv

To get started, we're going to clone

For this project, since we'll only be retrieving data we're going to use the LND REST API. The LND REST API provides swagger files, so we could use these to generate TypeScript references and a client. Because we're using a small subset of API's we'll create a simple client on our our own to retrieve the results

LND also has a gRPC API that can be used for streaming information about your node

https://api.lightning.community/#lnd-rest-api-reference

https://api.lightning.community/?#v1-graph

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#### Configuring `.env` to Connect to LND

We're going to add few application options to help us connect to our LND node.

In this application we use the `dotenv` package to simplify environment variables. We can populate a `.env` file with key value pairs and the application will treat these as environment variables.

Remember that environment variables can be read in Node.js from the `process.env` object. So if we have an environment variable `PORT`:

```
$ export PORT=8000
$ node app.js
```

This environment variable can be read with:

```typescript
const port = process.env.PORT;
```

So lets start by adding some values to `.env`. We'll add four new environment variables:

- `LND_HOST` is the host where our LND node resides
- `LND_READONLY_MACAROON_PATH` is the file path to the readonly Macaroon
- `LND_CERT_PATH` is the certificate we use to securely connect with LND

Fortunately, Polar provides us with a nice interface with all of this information. Polar also conveniently puts files in our local file system to make our dev lives a bit easier.

In Polar, to access Alice's node click on Alice and then click on the `Connect` tab. You will be shown the information on how to connect to the GRPC and REST interfaces. Additionally you will be given paths to the network certificates and macaroon files that we will need in `.env`.

![Connect to Alice](images/ch1_polar_connect_to_alice.png)

Go ahead and add the three environment variables defined above to `.env`. When you are done, your file should look something like:

```
# Express configuration
PORT=8001

# LND configuration
LND_HOST=https://127.0.0.1/8081
LND_READONLY_MACAROON_PATH=/home/lnuser/.polar/networks/1/volumes/lnd/alice/data/chain/bitcoin/regtest/readonly.macaroon
LND_CERT_PATH=/home/lnuser/.polar/networks/1/volumes/lnd/alice/tls.cert
```

#### Modify `Options.ts`

Now that our environment variables are in our configuration file, we need to get them into our application. The project comes with `app/Options.ts`. This class is where we will put properties that are needed to set up and control our application.

The class contains a factory method `fromEnv` that allows us to construct an `Options` instance from environment variables. We're going to modify the `Options` class to read our newly defined environment variables.

To do this, `Options` has a static property `Options.env` that maps the value of environment variables from `process.env` into known keys.

Start by modifying `app/Options.ts` by adding new properties on the `Options.env` mapping and reading the value from the corresponding environment variable.

The new properties to add to `env` are:

- LND_HOST
- LND_READONLY_MACAROON_PATH
- LND_CERT_PATH

After you add these value, your Options should look like:

```typescript
import "dotenv/config";

export class Options {
  public static env = {
    PORT: process.env.PORT,
    LND_HOST: process.env.LND_HOST,
    LND_READONLY_MACAROON_PATH: process.env.LND_READONLY_MACAROON_PATH,
    LND_CERT_PATH: process.env.LND_CERT_PATH,
  };

  public static async fromEnv(): Promise<Options> {
    for (const [key, value] of Object.entries(Options.env)) {
      if (!value) {
        throw new Error(`Required option ENV.${key} is not defined`);
      }
    }

    const port = Number(Options.env.PORT);

    return new Options(port);
  }

  constructor(readonly port: number) {}
}
```

Next we will need to create the properties on our `Options` object that will be read by our application. To do this, we modify the constructor and add some additional readonly arguments, similar to the existing `port` argument. In this case want to create:

- `lndHost` as a `string`
- `lndPort` as a `number`
- `lndReadonlyMacaroon` as a `Buffer`
- `lndCert` as a `Buffer`

Once you are done it will look like this:

```typescript
import "dotenv/config";
import fs from "fs/promises";

export class Options {
  public static env = {
    PORT: process.env.PORT,
    LND_HOST: process.env.LND_HOST,
    LND_PORT: process.env.LND_PORT,
    LND_READONLY_MACAROON_PATH: process.env.LND_READONLY_MACAROON_PATH,
    LND_CERT_PATH: process.env.LND_CERT_PATH,
  };

  public static async fromEnv(): Promise<Options> {
    for (const [key, value] of Object.entries(Options.env)) {
      if (!value) {
        throw new Error(`Required option ENV.${key} is not defined`);
      }
    }

    const port = Number(Options.env.PORT);

    return new Options(port);
  }

  constructor(
    readonly port: number,
    readonly lndHost: string,
    readonly lndPort: number,
    readonly lndReadonlyMacaroon: Buffer,
    readonly lndCert: Buffer
  ) {}
}
```

Most likely your IDE will be yelling at you right now as this code won't yet compile since our constructor is asking for five arguments and we're only supplying one in the `fromEnv` method. Don't worry, we'll get there next.

Note: In this example we use TypeScript's [Parameter Properties](https://www.typescriptlang.org/docs/handbook/2/classes.html#parameter-properties) feature. This feature creates class properties from `readonly` parameters. I like it because it saves a few keystrokes by removing the boilerplate of defining the property in the class, then assigning its value in the constructor. There are pros and cons to this approach, so feel free to construct your objects how think is best and in a way that is likely to reduce errors.

The last step we need is fix our compile error and supply our five arguments. You will note that I asked you to create the class properties as `Buffer` values. In the `fromEnv` method, we'll read the file's that are in the paths and use the resulting `Buffer` as the parameters to the constructor.

To do that we'll use `fs/promises` `readFile` method to perform an `async` read of the file contents.

Start by importing `fs/promises` at the top `Options.ts`:

```typescript
import fs from "fs/promises";
```

Then we create some variables by reading the files contents and assigning variables. Don't forget to cast `LND_PORT` into a number! You can use the `fs.readFile` method to read the contents of a file, such as:

```typescript
const contents: Buffer = await fs.readFile("path_to_some_file");
```

When all is done, `Options.ts` should be similal to:

```typescript
import "dotenv/config";
import fs from "fs/promises";

export class Options {
  public static env = {
    PORT: process.env.PORT,
    LND_HOST: process.env.LND_HOST,
    LND_PORT: process.env.LND_PORT,
    LND_READONLY_MACAROON_PATH: process.env.LND_READONLY_MACAROON_PATH,
    LND_CERT_PATH: process.env.LND_CERT_PATH,
  };

  public static async fromEnv(): Promise<Options> {
    for (const [key, value] of Object.entries(Options.env)) {
      if (!value) {
        throw new Error(`Required option ENV.${key} is not defined`);
      }
    }

    const port = Number(Options.env.PORT);
    const lndHost = Options.env.LND_HOST;
    const lndPort = Number(Options.env.LND_PORT);
    const lndReadonlyMacaroon = await fs.readFile(
      Options.env.LND_READONLY_MACAROON_PATH
    );
    const lndCert = await fs.readFile(Options.env.LND_CERT_PATH);

    return new Options(port, lndHost, lndPort, lndReadonlyMacaroon, lndCert);
  }

  constructor(
    readonly port: number,
    readonly lndHost: string,
    readonly lndPort: number,
    readonly lndReadonlyMacaroon: Buffer,
    readonly lndCert: Buffer
  ) {}
}
```

And with that, our application is has options to configure a connection to LND.

#### Creating an LND client

To connect to the LND REST API our project defines the `LndRestClient` class. Our first task is to modify our application startup to create an instance of this class. You will need to use the

```typescript
import { LndRestClient } from "./LndRestClient";
import { Options } from "./Options";
import { Server } from "./Server";

async function run() {
  const options = await Options.fromEnv();

  // Task: Create a LndRestClient
  const lnd: LndRestClient = undefined;

  const server = new Server(options);
  await server.setup();
  await server.listen();
}

run().catch((ex) => {
  console.error(ex);
  process.exit(1);
});
```

We will inject this client into our instance of the `Server` and will use it later to respond to make requests to the LND server.

To make this happen, define a property of the `LndRestClient` type in the `Server` class inside the `Server.ts` file.

```typescript
import express from "express";
import compression from "compression";
import bodyParser from "body-parser";
import { Options } from "./Options";
import { LndRestClient } from "./LndRestClient";

export class Server {
  public app: express.Express;

  constructor(readonly options: Options /* add parameter property */) {}

  public async setup() {
    this.app = express();
    this.app.use(bodyParser.json());
    this.app.use(compression());
  }

  public async listen(): Promise<void> {
    return new Promise((resolve) => {
      this.app.listen(Number(this.options.port), () => {
        console.log(`server listening on ${this.options.port}`);
        resolve();
      });
    });
  }
}
```

At this point, you application wont' compile. To get things working again, pass the `LndRestClient` instance you created in the previous exercise into the `Server` constructor in `index.ts`.

```typescript
import { LndRestClient } from "./LndRestClient";
import { Options } from "./Options";
import { Server } from "./Server";

async function run() {
  const options = await Options.fromEnv();
  const lnd = new LndRestClient(
    options.lndHost,
    options.lndReadonlyMacaroon,
    options.lndCert
  );
  const server = new Server(options); // FIX ME
  await server.setup();
  await server.listen();
}

run().catch((ex) => {
  console.error(ex);
  process.exit(1);
});
```

#### Create the Graph API

Since we're building a REST web service to power our front end application, we need to define an endpoint in our Express application.

In `Server.ts`, in the `setup` method we can add a request handler. We have a `getGraph` async method that is defined and have already created the mapping for the endpoint as `GET /api/graph` that will call this function.

In this exercise, use the `LndRestClient` that is part of the server to call the `graph` method. Return the results in a JSON response.

```typescript
import express from "express";
import compression from "compression";
import bodyParser from "body-parser";
import { Options } from "./Options";
import { LndRestClient } from "./LndRestClient";

export class Server {
  public app: express.Express;

  constructor(readonly options: Options, readonly lnd: LndRestClient) {}

  public async setup() {
    this.app = express();
    this.app.use(bodyParser.json());
    this.app.use(compression());
    this.app.get("/api/graph", (req, res, next) =>
      this.getGraph(req, res).catch(next)
    );
  }

  public async listen(): Promise<void> {
    return new Promise((resolve) => {
      this.app.listen(Number(this.options.port), () => {
        console.log(`server listening on ${this.options.port}`);
        resolve();
      });
    });
  }

  protected async getGraph(req: express.Request, res: express.Response) {
    // Obtain graph from LND Client and return it in a JSON response
  }
}
```

Dev Note: Express does not natively understanding `async` code but we can easily retrofit it. To do this we define the handler with a lambda function that has arguments for the `Request`, `Response`, and `next` arguments (has the type `(req, res, next) => void`). Inside that lambda, we then call our async code and attach the `catch(next)` to that function call. This way if our `async` function has an error, it will get passed to Express' error handler!

Once you have written this code, test our the server by running the `npm start` command and accessing `http://localhost:8001/api/graph. You should see information about the LND network. In this case, you should get a JSON result with two nodes (one for Alice and one for Bob) and a single edge for the channel between Alice and Bob.
