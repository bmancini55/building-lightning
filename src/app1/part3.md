# Creating an API

Our first coding task is going to be creating a REST API of our own to provide graph information to our application. We'll start by getting our server connected to Alice's LND node.

## Connecting to Alice's node

We've chosen to connect to LND for this application but we could just as easily use c-lightning or Eclair.

LND also a [Builder's Guide](https://docs.lightning.engineering/) that you may want to explore to learn more about commonly performed tasks.

LND has two ways we can interact with it from code: a [REST API](https://api.lightning.community/#lnd-rest-api-reference) and a [gRPC API](https://api.lightning.community/#lnd-grpc-api-reference). gRPC is a high performance RPC framework. With gRPC, the wire protocol is defined in a protocol definition file. This file is used by a code generators to construct a client in the programming language of your choice. gRPC is a fantastic mechanism for efficient network communication, but it comes with a bit of setup cost. The REST API requires less effort to get started but is less efficient over the wire. For applications with a large amount of interactivity, you would want to use gRPC connectivity. For this application we'll be using the REST API because it is highly relatable for web developers.

## LND API Client

Inside our `server` sub-project is the start of code to connect to LND's REST API. We'll add to this for our application.

Why are we not leveraging an existing library from NPM? The first reason is that it is a nice exercise to help demonstrate how we can build connectivity. Lightning Network is still a nascent technology and developers need to be comfortable building tools to help them interact with Bitcoin and Lightning Network nodes. The second and arguably more important reason is that as developers in the Bitcoin ecosystem, we need to be extremely wary of outside packages that we pull into our projects, especially if they are cryptocurrency related. Outside dependencies pose a security risk that could compromise our application. As such, my general rule is that runtime dependencies should generally be built unless it is burdensome to do so and maintain.

With that said, point your IDE at the `server/src/domain/lnd/LndRestTypes.ts` file. This file contains a subset of TypeScript type definitions from the [REST API](https://api.lightning.community/#lnd-rest-api-reference) documentation. We are only building a subset of the API that we'll need for understanding the graph.

## Exercise : Defining the `Graph` Type

In `LndRestTypes` you'll see our first exercise. It requires us to define the resulting object obtained by calling LND's [`/v1/graph`](https://api.lightning.community/#v1-graph) API. You will need to add two properties to the `Graph` interface. To help you, the `LightningNode` and `ChannelEdge` types are already defined. In TypeScript, you can define an array as such

```typescript
// server/src/domain/lnd/LndRestTypes

export interface Graph {
  // Exercise: define the `nodes` and `edges` properties in this interface.
  // These arrays of LightningNode and ChannelEdge objects.
}
```

## Exercise: Making the Call

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

## Exercise: Configuring `.env` to Connect to LND

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

![Connect to Alice](/images/ch1_polar_connect_to_alice.png)

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

## Exercise: Reading the Options

Now that our environment variables are in our configuration file, we need to get them into the application. The server project uses `server/src/Options` to read and store application options.

The class contains a factory method `fromEnv` that allows us to construct our options from environment variables. We're going to modify the `Options` class to read our newly defined environment variables.

This method is partially implemented, but your next exercise is to finish the method by reading the cert file into a Buffer.

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

## Exercise: Create the LND client

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

At this point, our server code is ready. We'll take a look at a few other things before we give it a test.

## Looking at LndGraphService

The `LndRestClient` instance that we just created will be used by `LndGraphService`. This class follows the adapter design pattern: which is a way to make code that operates in one way, adapt to another use. The `LndGraphService` is the place where we make the `LndRestClient` do things that our application needs.

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

For the purposes of fetching the graph, we simply call `getGraph` on the `LndRestClient` and return the results. But if we modified our application to use a generic graph instead of the one returned by LND, we could do that translation between the `Lnd.Graph` type and our application's graph here.

At this point your server should capable of connecting to LND!

## Looking at the Graph API

Since we're building a REST web service to power our front end application, we need to define an endpoint in our Express application.

Take a look at `server/src/Server`. We're doing a lot of things in this file for simplicity sake. About half-way down you'll see a line:

```typescript
// server/src/Server

app.use(graphApi(graphAdapter));
```

This code attaches a router to the Express application.

The router is defined in `server/src/api/GraphApi`. This file returns a function that accepts our `IGraphService` that we were just taking a look at. You can then see that we use the `IGraphService` inside an Express request handler where and then return the graph as JSON.

```typescript
// server/src/api/GraphApi

export function graphApi(graphService: IGraphService): express.Router {
  // Construct a router object
  const router = express();

  // Adds a handler for returning the graph. By default express does not
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

We can now run `npm run watch` at the root of our application and our server should start up and connect to LND without issue.

If you're getting errors, check your work by making sure Polar is running, the environment variables are correct, and you've correctly wired the code together.

You can now access [http://localhost:8001/api/graph](http://localhost:8001/api/graph) in your browser and you'll see information about the network as understood by Alice!
