# Putting It All Together

We have now completed all of the application's core logic. The only code that we have not discussed is the glue that holds it all together. As with our previous application, this one is bootstrapped inside of `server/Server.ts`. We're going to skip going into the heavy details of this class but you should take a look to see how things are wired up.

If you take take a look at `server/Server.ts` you can see that we construct an instance of `AppController` and call the `start` method.

```typescript
// start the application logic
await appController.start(
  "0000000000000000000000000000000000000000000000000000000000000001",
  1000
);
```

You can see that we start our application with the `seed` value of `0000000000000000000000000000000000000000000000000000000000000001`. You can start your application with any seed value and it will restart the game using that new seed.

The remainder of this file constructs the Express webserver and starts the WebSocket server. As with our previous application, a React application uses REST calls and WebSockets to communicate with our application code.

You may also notice that we hook into the `AppController` to listen for changes to links. As we talked about in the previous section, our `AppController` implements an observer pattern. Inside `Server.ts` we make the WebSocket server an observer of link changes that are emitted by the `AppController`.

```typescript
// broadcast updates to the client
appController.listener = (links: Link[]) =>
  socketServer.broadcast("links", links);
```

Lastly we have two API's that Express mounts: `server/api/LinkApi` and `server/api/InvoiceApi`. Both of these APIs parse requests and call methods in our `AppController` to retrieve the list of `Link` or create a new invoice for a user.

With that, your application is ready to fire up and test!

## Exercise: Run the Application!

You should be able to run the `npm run watch` from the root of the application to start it. You can now browse to http://192.168.0.1:8001 and try out the game!
