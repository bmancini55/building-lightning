# Code Setup

Before we get started writing code, we have a few small things we need to take care of.

## IDE Setup

For web applications, I like to use [Visual Studio Code](https://code.visualstudio.com/) as my IDE. It has excellent tooling for TypeScript and web development. I install the ESLint and Prettier plugins to give me real time feedback of any problems that my application may have.

## Runtime Setup

You will need to install the current version of [Node.js](https://nodejs.org/en/) by following the instructions for your operating system or using a tool like [NVM](https://github.com/nvm-sh/nvm#installing-and-updating).

If using NVM you can install the latest version with

```
nvm install node
```

Verify that your version of Node.js is at least 18+.

```
node --version
```

When you are in a project, if node or npm are not available, you may need to tell nvm which version of node to use in that directory. You can do that with with this command:

```
nvm use node
```

## Repository Setup

With general prerequisites setup, we can now clone the repository:

Clone the repository:

```
git clone https://github.com/bmancini55/building-lightning-graph.git
```

Navigate to the repository:

```
cd building-lightning-graph
```

The repository uses `npm` scripts to perform common tasks. To install the dependencies, run:

```
npm install
```

This will install all of the dependencies for the three sub-modules in the project: `client`, `server`, and `style`. You may get some warnings, but as long as the install command has exit code 0 for all three sub-projects you should be good. If you do encounter any errors, you can try browsing to the individual sub-project and running the `npm install` command inside each directory.

## Repository Walk-Through

The repository is split into three parts, each of which has a `package.json` to install Node.js dependencies for that sub-application. Each also has unique set of `npm` scripts that can be run. The three parts are:

1. `client` - Our React application lives in this directory.
1. `server` - Our Express server code lives in this directory.
1. `style` - Our code to create CSS lives here.

We will discuss the `client` and `server` sections in more detail as we go through the various parts of the application.
