# Visualizing the Lightning Network Graph

Welcome to Building on Lightning! This series will acquaint you with tools and techniques you will need to build Lightning Network applications. The first application we will build is a visualizer of Lightning Network nodes and channels. The end result is that our application will have an interface that queries a Lightning Network node and receives real-time updates from that node.

This project uses [TypeScript](https://www.typescriptlang.org/) in the [Node.js](https://nodejs.org/en/) runtime. If you're not familiar with TypeScript, I suggest you do a tutorial to help you understand the code in this tutorial. Node.js is a popular runtime for web development. When combined with TypeScript it allows us to build large applications with compile-time type checking. This helps us reduce mistakes and properly structure our applications for future changes and developers.

This project also uses [Express](https://expressjs.com) as the web framework. It is a fast, easy to use, and popular web framework. Lastly this project uses [React](https://reactjs.org/) and [D3](https://d3js.org/) for creating the visualization of the Lightning Network graph.

## The Lightning Network as a Graph

We'll start with a brief discussion of why we can conceptualize the Lightning Network as a graph. As you may be aware the Lightning Network consists of many computers running software that understands the Lightning Network protocols as defined in the [BOLT specifications](https://github.com/lightning/bolts/blob/master/00-introduction.md). The goal is to allow trustless, bidirectional, off-chain payments between nodes. So why is a picture of the network important?

Let's first consider payments between just two nodes: Alice and Carol. If Alice wants to pay Carol, she needs to know how to connect to Carol (the IP and port on which Carol's Lightning Network software is accessible). We refer to directly establishing a communication channel as becoming a peer. Once Alice and Carol are peers, Alice can establish a payment channel with Carol and finally pay her.

This sounds good, but if this was all the Lightning Network was, it has a major shortcoming. Every payment requires two nodes to become peers and establish channels. This means there are delays in first payments, on-chain cost to establish channels, and ongoing burden to manage the growing set of channels.

Instead the Lightning Network allows us to trustlessly route payments through other nodes in the network. If Alice wants to pay Carol, Alice doesn't need to be directly connected to Carol. Alice can pay Bob and Bob can pay Carol. However, Alice must know that she can pay through Bob.

The prerequisite for routed payments is that nodes need a view of what channels exist between other nodes. This is why an understanding of the network topology is important.

Conceptually we can think of the nodes and channels topology as a graph data structure. Each computer running Lightning Network software is a node in the graph. Each node is uniquely identified by a public key. The edges of the graph the public channels that exist between nodes. The channels are uniquely identified by the UTXO of the channel's funding transaction.

One consideration is that there is no such thing as a complete picture of the Lightning Network. The Lightning Network allows for private channels between nodes. Only nodes participating in a private channel will see these edges in their view of the network. As a result the Lightning Network is much larger than the topology created by public channels alone.

Another observation is that we often see visuals of the Lightning Network as an undirected graph. This makes sense when we are trying to get a picture of what channels exist. However there are complications when routing payments. Some balance of funds can exist on either side of the channel. This means that our ability to route through a channel is actually directional. For practical and privacy purposes, the balance on each side of the channel is opaque.

This is a lot to unpack, but if you're curious and want to dig deeper into how node's gossip about the topology and how they perform route path finding, refer to Chapters 11 and 12 in Mastering the Lightning Network.

With some understanding of why the network can be viewed as a Graph, let's get started with our application!

## Environment Setup

We'll get started by setting up your environment. Since we're going to build a Lightning Network application it should not be surprising that our infrastructure consists of a Bitcoin node and one or more Lightning Network nodes that we can control.

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

At this point, we are ready to write some code!

## Development Setup

### IDE Setup

For web applications, I like to use [Visual Studio Code](https://code.visualstudio.com/) as my IDE. It has excellent tooling for TypeScript and web development. I install the ESLint and Prettier plugins. These combine with the tooling in the project to improve your development experience.

### Runtime Setup

You will need to install [Node.js 16](https://nodejs.org/en/) by following the instructions for your operating system.

### Repository Setup

With general prerequisites setup, we can now clone the repository and check out the exercises branch:

Clone the repository:

```
git clone https://github.com/bmancini55/building-lightning-graph.git
```

Navigate to the repository:

```
cd building-lightning-graph
```

Checkout the exercises branch

```
git checkout exercises
```

The repository uses `npm` scripts to perform common tasks. To install the dependencies, run:

```
npm install
```

This will install all of the dependencies for the three sub-modules in the project: `client`, `server`, and `style`. If you encounter any errors, you can try browsing to the individual sub-project and running the `npm install` command inside that directory.

### Repository Walk-Through

The repository is split three parts, each of which has a `package.json` with the dependencies for the the sub-application part and a unique set of `npm` scripts that can be run. The three parts are:

1. `client` - Our React application lives in this directory.
1. `server` - Our Express server code lives in this directory.
1. `style` - Our code to create CSS lives here.

We will discuss the `client` and `server` sections in more detail as we go through the various parts of the application. If you would like to learn how to build these from scratch, you can refer to the Appendices.

## Creating an API

The first task is going to be creating a REST API of our own to provide graph information to our application. We'll start by getting our server connected to Alice's LND node.

### Connecting to Alice's node

We've chosen to connect to LND for this application but we could just as easily use c-lightning or Eclair.

LND also a [Builder's Guide](https://docs.lightning.engineering/) that you may want to explore to learn more about commonly performed tasks.

LND has two ways we can interact with it from code: a [REST API](https://api.lightning.community/#lnd-rest-api-reference) and a [gRPC API](https://api.lightning.community/#lnd-grpc-api-reference). gRPC is a high performance RPC framework. With gRPC, the wire protocol is defined in a protocol definition file. This file is used by a code generators to construct a client in the programming language of your choice. gRPC is a fantastic mechanism for efficient network communication, but it comes with a bit of setup cost. The REST API requires less effort to get started but is less efficient over the wire. For applications with a large amount of interactivity, you would want to use gRPC connectivity. For this application we'll be using the REST API because it is highly relatable for web developers.

### API Client

Inside our `server` sub-project, exists the start of an LND REST API client that we'll use for this application.

Why are we not leveraging an existing library from NPM? The first reason is that it is a nice exercise to help demonstrate how we can build connectivity. Lightning Network is still a nascent technology and developers need to be comfortable building tools to help them interact with Bitcoin and Lightning Network nodes. The second and arguably more important reason is that as developers in the Bitcoin ecosystem, we need to be extremely wary of outside packages that we pull into our projects, especially if they are cryptocurrency related. Outside dependencies pose a security risk that could compromise our application. As such, my general rule is that runtime dependencies should generally be built unless it is burdensome to do so and maintain.

With that said, point your IDE at the `server/src/domain/lnd/LndRestTypes.ts` file. This file contains a subset of TypeScript type definitions from the [REST API](https://api.lightning.community/#lnd-rest-api-reference) documentation. We are only building a subset of the API that we'll need for understanding the graph.

### Exercise : Defining the `Graph` Type

Here you'll see exercise 1. This exercise requires us to define the resulting object obtained by calling the [`/v1/graph`](https://api.lightning.community/#v1-graph) API. You will need to add two properties to the `Graph` interface. As a note, the `LightningNode` and `ChannelEdge` types are already defined!

```typescript
// server/src/domain/lnd/LndRestTypes

export interface Graph {
  // Exercise: implement this interface by adding the properties
  // returned in the result of the https://api.lightning.community/#v1-graph.
  // Note that the LightningNode and ChannelEdge types are already
  // defined below
}
```

### Exercise: Making the Call

Now that we've defined the results from a call to [`/v1/graph`](https://api.lightning.community/#v1-graph), we need to point our IDE at `server/src/domain/lnd/LndRestClient.ts` so we can write the code that makes this API call.

`LndRestClient` implements a basic LND REST client. We can add methods to it that are needed by our application. It also takes care of the heavy lifting for establishing a connection to LND. You'll notice that the constructor takes three parameters: `host`, `macaroon`, and `cert`. The `macaroon` is similar to a security token. The macaroon that you provide will dictate the security role you use when calling the API. The `cert` is a TLS certificate that enables a secure and authenticated connection to LND.

```typescript
// server/src/domain/lnd/LndRestClient

export class LndRestClient {
  constructor(
    readonly host: string,
    readonly macaroon: Buffer,
    readonly cert: Buffer
  ) {}
}
```

This class also has a `get` method that is a helper for making HTTP GET requests to LND. This helper method applies the macaroon and ensures the connection is made using the TLS certificate.

Your next exercise is to implement the `getGraph` method in `server/src/domain/lnd/LndRestClient.ts`. Use the `get` helper method to call the [`/v1/graph`](https://api.lightning.community/#v1-graph) API and return the results.

```typescript
// server/src/domain/lnd/LndRestClient

  public async getGraph(): Promise<Lnd.Graph> {
      // Exercise: use the `get` method below to call `/v1/graph` API
      // and return the results
  }
```

After this is complete, we should have a functional API client. In order to test this we will need to provide the macaroon and certificate.

### Exercise: Configuring `.env` to Connect to LND

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

Our next exercise is adding some values to `.env` inside the `server` sub-project. We'll add three new environment variables:

- `LND_HOST` is the host where our LND node resides
- `LND_READONLY_MACAROON_PATH` is the file path to the readonly Macaroon
- `LND_CERT_PATH` is the certificate we use to securely connect with LND

Fortunately, Polar provides us with a nice interface with all of this information. Polar also conveniently puts files in our local file system to make our lives as developers a bit easier.

In Polar, to access Alice's node by click on Alice and then click on the `Connect` tab. You will be shown the information on how to connect to the GRPC and REST interfaces. Additionally you will be given paths to the network certificates and macaroon files that we will need in `.env`.

![Connect to Alice](images/ch1_polar_connect_to_alice.png)

Go ahead and add the three environment variables defined above to `.env`.

```
# Express configuration
PORT=8001

# LND configuration
# Exercise: Provide values for Alice's node
LND_HOST=
LND_READONLY_MACAROON_PATH=
LND_CERT_PATH=
```

### Exercise: Reading the Options

Now that our environment variables are in our configuration file, we need to get them into the application. The server project uses `server/src/Options` to read and store application options.

The class contains a factory method `fromEnv` that allows us to construct our options from environment variables. We're going to modify the `Options` class to read our newly defined environment variables.

This method is partially implemented, but your next exercise is to finish the method by

```typescript
// server/src/Options

  public static async fromEnv(): Promise<Options> {
    const port: number = Number(process.env.PORT),
    const host: string = process.env.LND_HOST,
    const macaroon: Buffer = await fs.readFile(process.env.LND_READONLY_MACAROON_PATH),

    // Exercise: Using fs.readFile read the file in the LND_CERT_PATH
    // environment variable
    const cert: Buffer = undefined;

    return new Options(port, host, macaroon, cert);
  }
```

Note: In this example we use TypeScript's [Parameter Properties](https://www.typescriptlang.org/docs/handbook/2/classes.html#parameter-properties) feature. This feature creates class properties from `readonly` parameters. I like it because it saves a few keystrokes by removing the boilerplate of defining the property in the class, then assigning its value in the constructor. There are pros and cons to this approach, so feel free to construct your objects how think is best and in a way that is likely to reduce errors.

### Exercise: Create the LND client

The last step before we can see if our application can connect to LND is that we need to create the LND client! We will do this in the entrypoint of our server code `server/src/Server`.

In this exercise, construct an instance of the `LndRestClient` type and supply it with the options found in the `options` variable.

```typescript
// server/src/Server

  async function run() {
    // construct the options
    const options = await Options.fromEnv();

    // Exercise: using the Options defined above, construct an instance
    // of the LndRestClient using the options.
    const lnd: LndRestClient = undefined;

    // construct an IGraphService for use by the application
    const graphAdapter: IGraphService = new LndGraphService(lnd);
```

At this point, our server code is ready. We'll take a look at a few other things before give it a test.

### Looking at LndGraphService

The `LndRestClient` instance that we just created will be used by `LndGraphService`. This class follows the adapter design pattern: which is a way to make code that operates in one way, adapt to another use. The `LndGraphService` is the place were we make the `LndRestClient` do things that our application needs.

```typescript
export class LndGraphService extends EventEmitter implements IGraphService {
    constructor(readonly lnd: LndRestClient) {
        super();
    }

    /**
     * Loads a graph from LND and returns the type. If we were mapping
     * the returned value into a generic Graph type, this would be the
     * place to do it.
     * @returns
     */
    public async getGraph(): Promise<Lnd.Graph> {
        return await this.lnd.getGraph();
    }
```

For the purposes of fetching the graph, we simply call `getGraph` on the `LndRestClient` and return the results. But if we modified our application to use a generic graph instead of the one returned by LND, we could do that translation between the `Lnd.Graph` type and our application's graph.

### Looking at the Graph API

Now that you've correctly connected your application to LND! Since we're building a REST web service to power our front end application, we need to define an endpoint in our Express application.

Take a look at `server/src/Server`. We're doing a lot of things in this file for simplicity sake. About half-way down you'll see a line:

```typescript
// server/src/Server

app.use(graphApi(graphAdapter));
```

This code attaches a router to the Express application.

The router is defined in `server/src/api/GraphApi`. This file returns a function that accepts our `IGraphService` that we were just taking a look at. You can then see that we use the `IGraphService` inside an Express request handler where we return the results as JSON.

```typescript
// server/src/api/GraphApi

export function graphApi(graphService: IGraphService): express.Router {
  // construct a router object
  const router = express();

  // adds a handler for returning the graph. By default express doe not
  // understand async code, but we can easily adapt Express by calling
  // a promise based handler and if it fails catching the error and
  // supplying it with `next` to allow Express to handle the error.
  router.get("/api/graph", (req, res, next) => getGraph(req, res).catch(next));

  /**
   * Handler that obtains the graph and returns it via JSON
   */
  async function getGraph(req: express.Request, res: express.Response) {
    const graph = await graphService.getGraph();
    res.json(graph);
  }

  return router;
}
```

Dev Note: Express does not natively understanding `async` code but we can easily retrofit it. To do this we define the handler with a lambda function that has arguments for the `Request`, `Response`, and `next` arguments (has the type `(req, res, next) => void`). Inside that lambda, we then call our async code and attach the `catch(next)` to that function call. This way if our `async` function has an error, it will get passed to Express' error handler!

We can now run `npm start` in the command line and our server should start up and connect to LND without issue.

If you're getting errors, check your work by making sure Polar is running, the environment variables are correct, and you've correctly wired the code together.

You can also access `http://localhost:8001/api/graph` in your browser. You should see information about the network as understood by Alice!

## User Interface

Now that we have a functioning server, let's jump into the user interface! This application uses the React.js framework and D3.js. If you're not familiar with React, I suggest finding a tutorial to get familiar with the concepts and basic mechanics. We'll again be using TypeScript for our React code to help us add compile-time type-checking.

### Exploring the User Interface

The user interface sub-project lives inside the `client` folder of our repository. Inside `client/src` is our application code.

The entry point of the application is `App.tsx`. This code uses `react-router` to allow us to link URLs to various scenes of our application. Once we've built-up our entry point we embed the application into DOM.

```typescript
// client/src/App

import React from "react";
import ReactDom from "react-dom";
import { BrowserRouter } from "react-router-dom";
import { LayoutScene } from "./scenes/layout/LayoutScene";

ReactDom.render(
  <BrowserRouter>
    <LayoutScene />
  </BrowserRouter>,
  document.getElementById("app")
);
```

From this you will see that we render a single component, `<LayoutScene>`. It lives inside the `client/src/scenes/layout`. Inside this folder is where we define things related to our application layout.

The `LayoutScene` component is also where we use `react-router` to define our various scenes based on the URL path.

```typescript
// client/src/scenes/layout/LayoutScene

import React from "react";
import { Route, Routes } from "react-router-dom";
import { AppNav } from "./components/AppNav";
import { GraphScene } from "../graph/GraphScene";

export const LayoutScene = () => {
  return (
    <div className="layout">
      <div className="container-fluid mb-3">
        <AppNav />
      </div>
      <Routes>
        <Route path="/" element={<GraphScene />} />
      </Routes>
    </div>
  );
};
```

Here you can see that inside the `<Routes>` component we define a single `<Route>` that is bound to the root path `/` and it renders the `GraphScene` component which will be responsible for rendering our graph!

So our folder structure looks like this:

```
client\
  src\
    App.tsx
    scenes\
      layout\
        LayoutScene.tsx
      graph\
        GraphScene.tsx
```

And our code component hierarchy looks like this:

```
App
  LayoutScene
    GraphScene
```

Each of the scenes can also have components that are specific to the the scene. These are stored inside the `components` folder inside each scene.

```
client\
  src\
    App.tsx
    scenes\
      layout\
        LayoutScene.tsx
        components\
          NavBar.tsx
      graph\
        GraphScene.tsx
        components\
          Graph.tsx
```

Now that we've laid out how our application works let's build our application and see what happens. In the command line, navigate to the `client` folder and run the following command:

```
npm run watch
```

This command should build the React application and place it into the `dist` folder.

You can now use your browser to navigate to `http://localhost:8001` and view the application!

![Blank Slate](/images/ch1_app_01.png)

### Exercise: Loading the Graph

Now that we're setup need to wire up the graph API we previously created. To make our life easier we will use an `ApiService` to abstract the calls to our API endpoint.

In your IDE, navigate to `/client/src/services/ApiService.ts` and create a method that uses the get helper `get` to retrieve

```typescript
// client/src/services/ApiService

import { Lnd } from "./ApiTypes";

export class ApiService {
  constructor(readonly host: string = "http://127.0.0.1:8001") {}

  protected async get<T>(path: string): Promise<T> {
    const res = await fetch(path, { credentials: "include" });
    return await res.json();
  }

  // Exercise: Create a public fetchGraph method that returns Promise<Lnd.Graph>.
  // You can use the get helper method above by supplying it with an API path.
  public async fetchGraph(): Promise<Lnd.Graph> {
    return undefined;
  }
}
```

This class is conveniently accessible by using the `useApi` hook located in the `hooks` folder. By adding our `fetchGraph` method to the `ApiService`, we can gain access to it with the `useApi` hook inside any component! Feel free to take a look at the `useApi` hook code and if you're confused read up on React hooks.

### Exercise: Wire up the API Call

Next let's point our IDE at the `GraphScene` component in `client/src/scenes/graph` and see if we can wire up the API call for the graph to this scene.

For this exercise, inside the `useEffect` hook, call the api's `fetchGraph` method. Be mindful that this method returns a promise, which you will need to retrieve the results from. To test your code, simply log the results to the console.

```typescript
// client/src/scenes/graph/GraphScene

import React, { useEffect, useRef } from "react";
import { useApi } from "../../hooks/UseApi";
import { Graph } from "./components/Graph";

export const GraphScene = () => {
  const api = useApi();
  const graphRef = useRef<Graph>();

  useEffect(() => {
    // Exercise: Using the api, call the fetchGraph method. Since this returns a promise,
    // we need to use the `then` method to retrieve the results. With the results, call
    // `graphRef.current.createGraph` and add a console.log statement so you see the graph.
  }, []);

  return (
    <div className="container-fluid h-100">
      <div className="row h-100">
        <div className="col h-100">{<Graph ref={graphRef} />}</div>
      </div>
    </div>
  );
};
```

Dev Note: The `useEffect` hook has two arguments: a callback function and an array of variables that when changed will trigger the callback function. Providing an empty array means our callback function will only be called when the component mounts, which is the functionality we are looking for.

Dev Note: [Promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) are a mechanism for working with asynchronous operations. When a promise completes, the results are available in the `then` method.

When you refresh your browser, the background will now be gray but you won't yet see the graph yet. If you open your developer tools, you will see the graph output that you wrote with console.log!

![Console with Graph](/images/ch1_app_02.png)

### Graph Component Overview

The `Graph` component is a bit different from a normal React component because it is encapsulating D3. Typically React controls rendering to the DOM, but for this component React will only control the SVG element where the D3 Graph will be rendered.

We control D3 with two methods on the component: `createGraph` and `updateGraph`. Each method takes information from our domain and converts it into objects that D3 can control and render.

As a result, we transition from the declarative style of programming used by React and use imperative code to call these functions. If that's a little confusing, take a gander at `GraphScene` and `Graph`. Notice that `GraphScene` renders `Graph` as a child, but we use the `createGraph` method to push information into D3.

### Exercise: Creating the Graph

After loading the page, we don't yet see the graph because we haven't fully implemented the `createGraph` method in the `Graph` component. This method is responsible for converting our `Lnd.Graph` object into objects that can be used by D3.

As defined in `server/src/domain/lnd/LndRestTypes`, our `Lnd.Graph` object has two arrays: `nodes` and `edges`.

Each `Lnd.LightningNode` object has three properties that we will use:

- `pub_key` - a string that is the unique identifier for the node
- `color` - the color of the node that is specified by the node operator
- `alias` - the friendly name of the node that is specified by the node operator

Each `Lnd.ChannelEdge` object has three properties that we will use:

- `channel_id` - the unique identifier for the channel
- `node1_pub` - the identifier for the first node, when sorted, of the channel
- `node2_pub` - the identifier for the second node, when sorted, of the channel

Using this information we need to construct new objects that can be controlled by D3. We need to do
this because D3 will store rendering state on the objects. We don't want D3 to mutate the original
objects so we'll construct new ones that D3 can control.

This gets us to our next exercise. We need to modify the `Graph` component's `createGraph` method
to convert our Lightning graph objects into D3 controlled objects. To do this we create two arrays:

- one array for the graph's nodes created from our `Lnd.LightningNode` where our `pub_key` maps to `id`,
  and the `alias` maps to the D3 node's title.
  ```typescript
  interface D3Node {
    id: string;
    color: string;
    title: string;
  }
  ```
- one array for the graph's links created from our `Lnd.ChannelEdge` objects where the `channel_id` maps to the the `id` and `node1_pub` maps to `source` and `node2_pub` maps to target.
  ```typescript
  interface D3Link {
    id: string;
    source: string;
    target: string;
  }
  ```

```typescript
// client/src/scenes/graph/components/Graph

    createGraph(graph: LightningGraph) {
        // map the graph's nodes into d3 nodes
        this.nodes = [];

        // map the graph's channels into d3 links
        this.links = [];
```

Once we have created these maps we can refresh our browser and we should
see the current graph!

![Graph](/images/ch1_app_03.png)

## Real Time Server Updates

At this point we've successfully connected our user interface to a REST server! However what happens
if a new channel is created or a new node creates a channel? Our Lightning Network nodes will have
new graph information but we would need to manually refresh the page.

Go ahead and give it a try by creating a channel between Bob and Carol. When we refresh the browser
we should see a new link between Bob and Carol.

This is ok, but we can do better by passing updates to our user interface using WebSockets.

The WebSocket code on our server uses the [ws]() library and lives inside
the `SocketServer` class. This class maintains a set of connected sockets.
It also includes a `broadcast` method that allows us to send data for some
channel to all connected sockets.

```
{
  channel: string,
  data: T
}
```

This class is covered in more depth in [Appendix 1](appendix_1).

The last bit of code for WebSockets lives inside `server/src/index.ts`.
At the end of the `run` method, we create the `SocketServer` instance and
have it listen to the HTTP server for connections.

```typescript
// server/src/Server.ts
async function run() {
    // OTHER CODE IS HERE...

  // start the server on the port
    const server = app.listen(Number(options.port), () => {
        console.log(`server listening on ${options.port}`);
    });

    // start the socket server
    const socketServer = new SocketServer();

    // start listening for http connections
    socketServer.listen(server);
```

Back in our server code's `LndGraphService` is a method `subscribeGraph` that we need to modify. This
method subscribes to LND API's `subscribeGraph` method. We need to impl.ement this method to convert LND's
graph updates into our `LightningGraphUpdate` type and fire an event

```typescript
  public async subscribeGraph(): Promise<void> {
        // Exercise:
        // 1. Using the LND Client, subscribe to graph updates using the
        //    `subscribeGraph` method
        // 2. Handle each update by converting the LND `GraphUpdate` into
        //    a `LightningGraphUpdate` used by our application
        // 3. Emit the `LightningGraphUpdate` with this.emit("update", update);
  }
```

Dev Note: This class is an [EventEmitter](). EventEmitters can use the
`emit` method to tell other classes that something has happened. These
other classes are "observers" and can listen using the `on` method.
Using EventEmitters allows us to keep code decoupled and avoid messy
callback nesting.

Once you have implemented `subscribeGraph` we need to do two things:

1. have the server subscribe to updates
2. send those updates to any connected WebSockets

To add these features we'll add them to the bottom out `Server.ts`.

```typescript
// server/src/Server.ts

async function run() {
  // other code is here...

  // start the socket server
  const socketServer = new SocketServer();

  // start listening on the socket
  socketServer.listen(server);

  // Exercise: On the `lndGraphService`, attach an event handler for
  // graph updates and broadcast them to all WebSockets using
  // socketServer.broadcast. You can pick a channel name, such as "graph".

  // subscribe to graph updates
  lndGraphAdapter.subscribeGraph();
}
```

That's all there is to it! You should now be able to connect a WebSocket
to the server and receive updates.

To test this code, you can generate graph updates by closing or
opening a channel.

## Real Time User Interface

Now that our WebSocket server is sending update, we need to wire these
updates into our user interface.

The application already has some code to help us. We use React's context
to establish a long-lived WebSocket that can be used by any component.
This code lives in `client/src/context/SocketContext.tsx` and is covered
in more depth in [Appendix 2]().

We also have a hook, `useSocket` that lives in `client/src/hooks/UseSocket.ts`.
This hook allows us to retrieve the websocket and subscribe to events for
a particular channel, for example:

```typescript
export const SomeComponent = () => {
  const socket = useSocket("some_channel", (data) => {
    // do something with data
    console.log(data);
  });
};
```

The last thing we should know is that in order for this to work, we need
to establish the React Context higher in the component hierarchy. This is
necessary so that our hook can acesss the socket context.

To make this magic happen, we add the context via the `<SocketProvider>`
component to our application's root, `App.txs`.

```typescript
// client/src/App.tsx
import React from "react";
import ReactDom from "react-dom";
import { BrowserRouter } from "react-router-dom";
import { SocketProvider } from "./context/SocketContext";
import { LayoutScene } from "./scenes/layout/LayoutScene";

ReactDom.render(
  <SocketProvider>
    <BrowserRouter>
      <LayoutScene />
    </BrowserRouter>
  </SocketProvider>,
  document.getElementById("app")
);
```

With the lay of the land defined, we can now embark on our journey to
wire up real time updates.

The logical place to add this connection is the `GraphScene` component.
As previously established, this scene is responsible for wiring up data
connections for graph related components.

Pointing our IDE at the `GraphScene` component our next exercise is
implementing the socket handler. Using the `useSocket` hook, subscribe
to the same channel that you established on the server. The handler
function should call the `graphRef.current.createGraph` method on the
graph component.

```typescript
// client/src/scenes/graph/GraphScene.tsx
import React, { useEffect, useRef } from "react";
import { useSocket } from "../../hooks/UseSocket";
import { useApi } from "../../hooks/UseApi";
import { Graph } from "./components/Graph";

export const GraphScene = () => {
  const api = useApi();
  const graphRef = useRef<Graph>();

  useEffect(() => {
    api.fetchGraph().then((graph) => {
      console.log("received graph", graph);
      graphRef.current.createGraph(graph);
    });
  }, []);

  // Exercise: with the useSocket hook, subscribe to the channel that
  // the server is sending graph updates on. The handler function for
  // this channel should call `graphRef.current.updateGraph` with the
  // information.

  return (
    <div className="container-fluid h-100">
      <div className="row h-100">
        <div className="col h-100">{<Graph ref={graphRef} />}</div>
      </div>
    </div>
  );
};
```

We are almost done! The final step is implementing the `updateGraph`
method to translate the `LightningGraphUpdate` into `D3Node` and `D3Link`
types used by the graph.

The update we receive from the server consists of three pieces of data:

1. node updates - we need to change the color or title of the node in
   the graph.
2. channel updates - we need to add new links to our graph if the link
   does not already exist.
3. channel closes - we need to remove links from our graph.

```typescript
// client/src/scenes/graph/components/Graph.tsx
updateGraph(update: LightningGraphUpdate) {
    // Exercise:
    // 1. For each Lightning node update, update the corresponding node's
    // title and color.
    // 2. For each channel update, add a link to the D3 graph if it does
    // not already exist.
    // 3. For each channel close, remove the link from the D3 graph

    this.draw();
}
```

After completing this exercise we will have everything needed for our
graph to be functional. Try adding or removing a channel, you should
see our graph application automatically update with the changes!

## Further Exploration

This is just the beginning of interesting things we can do to help us visualize the Lightning Network. Spend some time working on further exploration of this application.

- How would you add other information to our user interface?
- How would you connect to c-lightning or eclair? What would need to change about the architecture?
- How would you connect to testnet or mainnet? How would you address scaling given that the main network has 10's of thousands of nodes and channels?
- How would you make our application production ready? How would you add testing? What happens if LND restarts? What happens if the REST/WebSocket server restarts?
