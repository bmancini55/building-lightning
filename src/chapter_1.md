# Visualzing the Lightning Graph

This application will use Node.js with Typescript, Express, and D3.js to create a visualization of the Lightning Network graph.

## Development Environment

A development environment for the Lightning network typeically consists of a Bitcoin node running in simnet mode and one or more Lightning Network nodes. Getting all this running can be time consuming. Fortunately, there is the tool [Polar](https://lightningpolar.com) that allows us to spin up Lightning network testing environments easily!

Our first step is to download and install Polar for your operating system from the [website](https://lightningpolar.com).

For a Linux system, it will be as an AppImage. You will need to grant executable rights to the file, then you can run the application.

Once Polar is running, you can create a new network. Polar allows us to run many different networks with varying configurations. For this application we will start the network with 1 LND node, 1 c-lightning node, 1 Eclair, and 1 Bitcoin Core node. Provide a name for this network.

![Polar Network](images/ch1_polar_create.png)

Start the network once it has been created. Polar will launch Docker containers for each of the nodes in your network.

Polar also provides a few tools to allow us to easily perform common tasks.

We will start by depositing some funds into Alice's node. To do this, click on Alice's node, then click on the `Actions` tab.

We will then deposit 1,000,000 satoshis into Alice's node. When you click the `Deposit` button, the Bitcoin Core node running in simnet will create new blocks to an address and 0.01000000 bitcoin (1,000,000 satoshis) will deposited into an address controlled by Alice's Lightning Network node.

![Alice with 1mil Sats](images/ch1_polar_deposit.png)

Now that Alice has some funds, she can create a channel with another node on the network. We can do this by opening an outgoing channel by clicking the `Outgoing` button in the `Open Channel` section of Alice's Actions tab.

Let's choose Bob as the channel counterparty and fund the channel with 250,000 satoshis.

![Alice to Bob Create Channel](images/ch1_polar_open_channel.png)

We should now see a channel link between Alice and Bob in our channel graph.

![Alice to Bob Channel](images/ch1_polar_alice_bob.png)

At this point, we are ready to connect to Alice's node via the API.

### Connecting to Alice's node




## Server Project Setup

For this application we'll be serving requets using Node.js and express.  The first thing we need to do is get the Node.jS runtime enabled. 

Install the current [LTS version of Node.js](https://nodejs.org/en/download/0). Once installed, ensure Node.js is running and the version is expected:

```bash
$ node --version
v16.14.0
```

Next we'll need to create a new Node.js application called `lightning-graph`.

```bash
mkdir lightning-graph
cd lightning-graph
```


When building web application, I like to split the various pieces of the application into a few components:
1. Server - provides an API that the front-end communicates with via REST or Websockets
2. Client application - our application code front end
3. Styling - code related to stylesheets
4. Public data - contains images, html files, etc

Splitting the application into parts gives us flexibility on tooling, testing, build, and runtime capabilities for each part with minimial effort needed to manage the entire process. 

To get started, let's focus on the server first and create a server

```bash
$ mkdir server
$ cd server
```

Next we'll initialize our application

```bash
$ npm init -y
```

This creates a `package.json` file that contains default information. This file will changes as we add additional development packages to our project. We'll also customize the scripts to help us during development and when the application is running.

```json
{
  "name": "server",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

Next we'll install TypeScript and the `ts-node` runtime. We'll install these as runtime dependencies. 

```bash
npm install typescript @types/node ts-node 
```

This command installs the latest version of TypeScript, the type definitions for Node.js and the ts-node runtime. This runtime uses just-in-time compiling of TypeScript so that we can run Node.js directly with TypeScript code.

Now we need to configure TypeScript for our server application by creating a `tsconfig.json` file:

```bash
touch tsconfig.json
```

Inside our `tsconfig.json` file we will configure the compliation process for TypeScipt to compile to the most recent version of the JavaScript specification and we'll point it at the `app` folder where our source code will live.

```json
{
    "compilerOptions": {
      "target": "ES2020"
    },
    "include": ["app"]
}
```

Next let's install some development tooling to help us write code with fewer errors. We'll start with `prettier` to perform code formatting for us so we can focus on our code instead of spacing.

```bash
npm install --save-dev prettier
```

We'll configure `.prettierrc` file. I personally prefer a max line with of 100, double quotes, and trailing commas in my code. 
 
```bash
touch .prettierrc
```

```json
{
    "printWidth": 100,
    "singleQuote": false,
    "trailingComma": "all",
    "arrowParens": "avoid"
}
```

The last dev tool we'll install is `eslint`. We'll use this for checking our TypeScript code for syntax errors or common pitfalls. We need to install support for prettier and TypeScript in eslint as well.

```bash
npm install --save-dev\
    eslint\
    @typescript-eslint/eslint-plugin\
    @typescript-eslint/parser\
    eslint-config-prettier
```

Lastly we'll create the `.eslintc` file that adds our plugins, parsers, and specifies the environment (Node.js with ES6 support) that we're operating under.

```bash
touch .eslintrc
```

```json
{
    "env": {
        "browser": false,
        "es6": true,
        "node": true
    },
    "extends": [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended",
        "plugin:@typescript-eslint/recommended-requiring-type-checking",
        "prettier",
        "prettier/@typescript-eslint"
    ],
    "parser": "@typescript-eslint/parser",
    "plugins": ["@typescript-eslint"]
}
```

If you're using Visual Studio Code, you can install Prettier and Eslint plugins and you'll get real time formatting and error handling for your code. This will greatly improve your speed at writing code. 


Now we can install some packages for our actually API. We're going to use `express` to serve our REST API. We're going to use the `body-parser` middleware package to add the ability to parse JSON requests for our API. We'll also install `compression` middleware package to automatically GZIP responses that we send to the client. Lastly we incldue the type defintions via the `@types/express`, `@types/body-parser`, and `@types/compression` packages. These definitions allow TypeScript to understand the modules.

```bash
npm install express body-parser compression @types/express @type/body-parser @types/compression
```

Now that we have the project tooling setup, we can begin scaffolding the server application. Create a folder called `app` and create a file called `app/index.ts`

```bash
$ mkdir app
$ touch app/index.ts
```

This will be application entrypoint and will be used to launch our application.

Next let's scaffold our server.  We create a new `express` application. Then using that application we listn on port 8000. When the server successfully starts we write to the console that the service has started.

```typescript
import express from "express";

const app: express.Express = express();

app.listen(8000, () => {
    console.log("listening port 8000");
});
```

Next we need to start the application, we will use `ts-node` to do this. In our `package.json` file we add the `start` script with the following command:

```
ts-node app
```

Our `package.json` should look similar to:

```json
{
  "name": "server",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "ts-node app"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "@types/body-parser": "^1.19.2",
    "@types/compression": "^1.7.2",
    "@types/express": "^4.17.13",
    "@types/node": "^17.0.21",
    "body-parser": "^1.19.2",
    "compression": "^1.7.4",
    "express": "^4.17.3",
    "ts-node": "^10.7.0",
    "typescript": "^4.6.2"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^5.14.0",
    "@typescript-eslint/parser": "^5.14.0",
    "eslint": "^8.11.0",
    "eslint-config-prettier": "^8.5.0",
    "prettier": "^2.5.1"
  }
}
```

We can then start the server using `npm start` and we should see the server start:

```bash
$ npm start

> server@1.0.0 start
> ts-node app

listening port 8000
```

With this we have scaffolded our server project! You can also take this scaffold and create a template project on GitHub. This will help you create applications using the baseline tooling without requiring you to start from scratch every time.

We're now set up and ready to being writing some code for this project or others!

## Server Application







## Understanding the Lightning Graph

## Polar development environment

https://lightningpolar.com/

Download Polar for you environment.


## LND Connectivity


For this project, since we'll only be retreiving data we're going to use the LND REST API. The LND REST API provides swagger files, so we could use these to generate TypeScript references and a client. Because we're using a small subset of API's we'll create a simple client on our our own to retrieve the results




LND also has a gRPC API that can be used for streaming information about your node


https://api.lightning.community/#lnd-rest-api-reference



