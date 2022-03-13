# Visualzing the Lightning Graph

This application will use Node.js with Typescript, Express, and D3.js to create a visualization of the Lightning Network graph. 

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

Our `package.json` will look similar to this:

```bash
$ cat package.json
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

With this we have scaffolded our server project! You can also take this scaffold and create a template project on GitHub. This will help you create applications using the baseline tooling without requiring you to start from scratch every time.

We're now set up and ready to being writing some code!

## Server Application







## Understanding the Lightning Graph

## Polar development environment

https://lightningpolar.com/

Download Polar for you environment.


## LND Connectivity


For this project, since we'll only be retreiving data we're going to use the LND REST API. The LND REST API provides swagger files, so we could use these to generate TypeScript references and a client. Because we're using a small subset of API's we'll create a simple client on our our own to retrieve the results




LND also has a gRPC API that can be used for streaming information about your node


https://api.lightning.community/#lnd-rest-api-reference



