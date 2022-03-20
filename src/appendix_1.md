# Scaffolding a Server Project

This section will walk you through building a server application from scratch using Node.js and Express. Once complete, you can create a template project and use it to quickly build applications in the future!

The first thing we need to do is get the Node.jS runtime enabled.

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
    @typescript-eslint/parser
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
  "plugins": ["@typescript-eslint"],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "project": "./tsconfig.json"
  },
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended"]
}
```

If you're using Visual Studio Code, you can install Prettier and Eslint plugins and you'll get real time formatting and error handling for your code. This will greatly improve your speed at writing code.

Now we can install some packages for our server. We're going to use `express` to serve our REST API. We're going to use the `body-parser` middleware package to add the ability to parse JSON requests for our API. We'll also install `compression` middleware package to automatically GZIP responses that we send to the client. We'll use `dotenv` to read information from `.env` file into `process.env` which is helpful for development and provides flexibility for deployment.Lastly we include the type defintions via the `@types/express`, `@types/body-parser`, and `@types/compression` packages. These definitions allow TypeScript to understand the modules.

```bash
npm install express body-parser compression dotenv @types/express @type/body-parser @types/compression
```

Now that we have the project tooling setup, we can begin scaffolding the server application.

### Options for the Server

Lets first start by creating teh `.env` file.

```bash
$ touch .env
```

You'll also want to ensure that you add `.env` to your `.gitignore` file to prevent you from accidentally commiting secrets into source control.

Inside the `.env` file, we'll add a single value to configure the `PORT` that express should listen on.

```
# Express configuration
PORT=8000
```

Next create a folder called `app`. This is where our source code will live.

```bash
$ mkdir app
```

First let's create an `app/Options.ts` that will read information from the environment variables and construct an options object that contains our applications configuration options. We start by creating the `Options` type and assigning a single property `port` that we mark as `readonly`. Doing so will automatically create the `port` property on the object and disallow it from being modified.

```typescript
import "dotenv/config";

export class Options {
  constructor(readonly port: number) {}
}
```

Next we'll add the the `dotenv` package to inject values from the `.env` file into `process.env` environment variables. We'll also define a static property on the class called `env` that maps values from `process.env`. We do this so we have an inventory of configurations that we should have obtained from the environment.

```typescript
import "dotenv/config";

export class Options {
  public static env = {
    PORT: process.env.PORT,
  };

  constructor(readonly port: number) {}
}
```

The last step is creating a `fromEnv` factory function that will return our `Option` instance. In this method, we can that all required keys were provided, whether the supplied values are correct, or other checks we may have. After we have performed these checks, we return an instance of `Options` with the values we obtained from our configuration file.

```typescript
import "dotenv/config";

export class Options {
  public static env = {
    PORT: process.env.PORT,
  };

  constructor(readonly port: number) {}

  public static async fromEnv(): Promise<Options> {
    for (const [key, value] of Object.entries(Options.env)) {
      if (!value) {
        throw new Error(`Required option ENV.${key} is not defined`);
      }
    }
    return new Options(Number(Options.env.PORT));
  }
}
```

As we build out our application, we can add additional configuration values to the `.env` file and add properties to our `Options` class so that our application can consume these values

### Scaffold the Server

Now that we have options, let's construct our server object by creating the `app/Server.ts` file.

Inside this file we construct a class to encapsulate the express application. We have two methods `setup` and `listen`.

```typescript
import express from "express";
import compression from "compression";
import bodyParser from "body-parser";
import { Options } from "./Options";

export class Server {
  public app: express.Express;

  constructor(readonly options: Options) {}

  public async setup() {
    this.app = express();

    // add JSON body parsing
    this.app.use(bodyParser.json());

    // add GZIP compression to responses
    this.app.use(compression());

    // mount routers here
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

The `setup` method is where we build the Express application. This method is marked as `async` so that we can perform asynchronous setup if needed. In `setup` you can see that we construct the application and mount the `body-parser` and `compression` middleware. As our application grows, we can mount additional application routers into this method.

The `listen` method starts the express server and converts the callback passing style into a promise so the consumer can call `await server.listen()`.

### Entrypoint for the Server

The last piece is creating the entrypoint of the application `app/index.ts`. In this file we create a single `async` function `run`. This function will create our server, call `setup` and `listen`. If we need to do any additional configuration, we can perform it here and pass it into our server.

```typescript
import { Options } from "./Options";
import { Server } from "./Server";

async function run() {
  // additional configurations here
  const options = Options.fromEnv();
  const server = new Server(options);
  await server.setup();
  await server.listen();
}

run().catch((ex) => {
  console.error(ex);
  process.exit(1);
});
```

We also invoke the server by calling `run`. Since it is a promise, we need to handle any errors that are created. We do this by logging the error and existing with a non-zero exit code to indicate an error.

Now that we have an application entrypoint, we can start the application. We will use `ts-node` to do this. In our `package.json` file we add the `start` script with the following command:

```
ts-node app
```

Our `package.json` should now look similar to:

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
    "dotenv": "^16.0.0",
    "express": "^4.17.3",
    "ts-node": "^10.7.0",
    "typescript": "^4.6.2"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^5.14.0",
    "@typescript-eslint/parser": "^5.14.0",
    "eslint": "^8.11.0",
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
