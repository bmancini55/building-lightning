# Real Time Server Updates

At this point we've successfully connected our user interface to a REST server! However what happens if a new channel is created or a new node creates a channel? Our Lightning Network nodes will have new graph information but we would need to manually refresh the page.

Go ahead and give it a try by creating a channel between Bob and Carol. When we refresh the browser we should see a new link between Bob and Carol.

This is ok, but we can do better by passing updates to our user interface using WebSockets.

## Exploring WebSocket Code

The WebSocket code on our server uses the [ws](https://www.npmjs.com/package/ws) library and lives inside the `SocketServer` class. You don't have to make any changes to it, but you may want to take a look at it. This class maintains a set of connected sockets. It also includes a `broadcast` method that allows us to send data for some channel to all connected sockets. We'll use this `broadcast` method shortly to send graph updates to all connected WebSockets.

The code to start the `SocketServer` lives inside `Server`. At the end of the `run` method, we create the `SocketServer` instance and have it listen to the HTTP server for connections.

```typescript
// server/src/Server

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

All of this is ready to go, all we need to do is subscribe to updates from LND and do something with them.

## Exercise: Subscribe to Updates

Back in our server code's `LndGraphService` is a method `subscribeGraph` that we need to implement. This method subscribes to graph updates from LND using it's `subscribeGraph` method. The requirement for this function is that it needs to emit these updates as events.

```typescript
  public async subscribeGraph(): Promise<void> {
    // Exercise: subscribe to the Lnd graph updates using `this.lnd.subscribeGraph`
    // and emit a "update" event each time the handler is called.
  }
```

Dev Note: This class is an [EventEmitter](https://nodejs.dev/learn/the-nodejs-event-emitter). EventEmitters can use the `emit` method to tell other classes that something has happened. These other classes are "observers" and can listen using the `on` method. Using EventEmitters allows us to keep code decoupled and avoid messy callback nesting.

## Exploring WebSocket Broadcasting

The next logical step is consuming the `update` event that we just created and sending the update to the client over a WebSocket. If you navigate back to the trusty `Server` you will find some interesting code at the bottom of the `run` function.

```typescript
// server/src/Server

async function run() {
  // other code is here...

  // construct the socket server
  const socketServer = new SocketServer();

  // start listening for http connections using the http server
  socketServer.listen(server);

  // attach an event handler for graph updates and broadcast them
  // to WebSocket using the socketServer.
  graphAdapter.on("update", (update: Lnd.GraphUpdate) => {
    socketServer.broadcast("graph", update);
  });

  // subscribe to graph updates
  graphAdapter.subscribeGraph();
}
```

We subscribe to the `update` event on `graphAdapter` that we just implemented. In the event handler we then broadcast the update to all of the WebSockets.

After the event handler is defined, all of the plumbing is in place to for updates to go from `LND -> LndRestClient -> LndGraphAdapter -> WebSocket`.

You should now be able to connect a WebSocket to the server and receive updates by generating channel opens or closes in Polar.

# Real Time User Interface

Now that our WebSocket server is sending updates, we need to wire these updates into our user interface.

## Exploring Socket Connectivity

The application already has some code to help us. We use React's context to establish a long-lived WebSocket that can be used by any component in the component hierarchy. This code lives in `client/src/context/SocketContext`.

To integrate this context into our components we can use a custom hook: `useSocket` that lives in `client/src/hooks/UseSocket`. This hook allows us to retrieve the websocket and subscribe to events for a any channel.

```typescript
export const SomeComponent = () => {
  const socket = useSocket("some_channel", (data) => {
    // do something with data
    console.log(data);
  });
};
```

The last thing we should know is that in order for this to work, we need to establish the React Context higher in the component hierarchy. A great place is at the root!. We add the context via the `SocketProvider` component in our application's root component: `App`.

```typescript
// client/src/App

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

With the lay of the land defined, we can now embark on our journey to finish the real time updates.

## Exercise: Subscribe to Updates

The logical place to subscribe to updates is in the `GraphScene` component. As previously established, this scene is responsible for wiring up data connections for graph related components.

Pointing our IDE at the `GraphScene` component our next exercise is implementing the socket handler. Using the `useSocket` hook, subscribe to `graph` channel. The handler function should call the `graphRef.current.updateGraph` method on the graph component.

```typescript
// client/src/scenes/graph/GraphScene

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

  useSocket("graph", (update: Lnd.GraphUpdate) => {
    // Exercise: Call `graphRef.current.updateGraph` with the update
  });

  return (
    <div className="container-fluid h-100">
      <div className="row h-100">
        <div className="col h-100">{<Graph ref={graphRef} />}</div>
      </div>
    </div>
  );
};
```

## Exercise: Update the Graph

We are almost done! The final step is completing the `updateGraph` method. This method converts our `Lnd.GraphUpdate` object into `D3Node` and `D3Link` objects.

The `Lnd.GraphUpdate` object we receive from the server is defined in `server/src/domain/lnd/LndRestTypes`. It consists of four pieces of data that we care about:

1. new nodes that are don't yet have in the graph
1. existing nodes that need to have their title and alias updated
1. new channels that we need to add to the graph
1. closed channels that we need to remove from the graph

The `updateGraph` method is partially implemented for the first three conditions. Your last task is to remove a channel from the links if it has been closed.

```typescript
// client/src/scenes/graph/components/Graph

  updateGraph(update: Lnd.GraphUpdate) {
      // Updates existing nodes or adds new ones if they don't already
      // exist in the graph
      for (const nodeUpdate of update.result.node_updates) {
          const node = this.nodes.find(p => p.id === nodeUpdate.identity_key);
          if (node) {
              node.title = nodeUpdate.alias;
              node.color = nodeUpdate.color;
          } else {
              this.nodes.push({
                  id: nodeUpdate.identity_key,
                  color: nodeUpdate.color,
                  title: nodeUpdate.alias,
              });
          }
      }

      // Adds new channels to the graph. Note that for the purposes of
      // our visualization we only care that a link exists. We will end
      // up receiving two updates, one from each node and we just add
      // the first one.
      for (const channelUpdate of update.result.channel_updates) {
          const channel = this.links.find(p => p.id === channelUpdate.chan_id);
          if (!channel) {
              this.links.push({
                  source: channelUpdate.advertising_node,
                  target: channelUpdate.connecting_node,
                  id: channelUpdate.chan_id,
              });
          }
      }

      // Exercise: Remove closed channels from `this.links`.

      this.draw();
  }
```

After completing this exercise we will have everything needed for our graph to be functional. Try adding or removing a channel, you should see our graph application automatically update with the changes! Keep in mind that it may take a moment for changes to propagate throughout your network.
