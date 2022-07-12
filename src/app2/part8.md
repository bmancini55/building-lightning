# Putting It All Together

We have now completed all of the applications core logic. The only code that we have talked about is the glue that holds it all together. As with our previous application the application is bootstrapped inside of `server/Server.ts`. We're going to skip going into the heavy details of these but you should take a look to become familiar.

If you take take a look at `server/Server.ts` you can see that we construct an instance of `AppController` and call the `start` method.

```typescript
// start the application logic
await appController.start(
  "0000000000000000000000000000000000000000000000000000000000000001",
  1000
);
```

You can see that we start our application with the seed value of `0000000000000000000000000000000000000000000000000000000000000001`. You can start your application with any seed value it will restart the game using that new seed.

The remainder of this file constructs the Express webserver and starts the WebSocket server.

You may also notice that we hook into the `AppController` to listen for changes to links. We broadcast those events over connected WebSockets.

```typescript
// broadcast updates to the client
appController.listener = (links: Link[]) =>
  socketServer.broadcast("links", links);
```

Lastly can take a look our two API's: `server/api/LinkApi` and `server/api/InvoiceApi`. Both of these APIs parse requests and call methods in our `AppController` to retrieve the list of `Link` or create a new invoice for a user.


With that, your application is ready to fire up and test! You should be able to run the `npm start` from the command line to start the application!
