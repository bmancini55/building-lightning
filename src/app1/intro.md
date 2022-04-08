# Visualizing the Lightning Network Graph

Welcome to Building on Lightning! This series will acquaint you with tools and techniques you will need to build Lightning Network applications. The first application we will build is a visualizer of the nodes and channels from the perspective of one node in Lightning Network. You will learn how to connect a web application to a Lightning Network node and receive real-time updates from that node.

This project uses [TypeScript](https://www.typescriptlang.org/) in the [Node.js](https://nodejs.org/en/) runtime. If you're not familiar with TypeScript, you may want to do a tutorial to help you understand the code. Node.js is a popular runtime for web development. When combined with TypeScript it allows us to build large applications with compile-time type checking. This helps us reduce mistakes and properly structure our applications for future changes. This project also uses [Express](https://expressjs.com) as the web framework. It is a fast, easy to use, and popular web framework. Lastly this project uses [React](https://reactjs.org/) and [D3](https://d3js.org/) for creating the visualization of the Lightning Network graph.

## The Lightning Network as a Graph

We'll start with a brief discussion of why we can conceptualize the Lightning Network as a graph. The Lightning Network consists of many computers running software that understands the Lightning Network protocols as defined in the [BOLT specifications](https://github.com/lightning/bolts/blob/master/00-introduction.md). The goal is to allow trustless, bidirectional, off-chain payments between nodes. So why is a picture of the network important?

Let's first consider payments between just two nodes: Alice and Carol. If Alice wants to pay Carol, she needs to know how to connect to Carol (the IP and port on which Carol's Lightning Network software is accessible). We refer to directly establishing a communication channel as becoming a peer. Once Alice and Carol are peers, Alice can establish a payment channel with Carol and finally pay her.

This sounds good, but if this was all the Lightning Network was, it has a major shortcoming. Every payment requires two nodes to become peers and establish channels. This means there are delays in sending a first payment, on-chain cost to establish channels, and ongoing burden to manage the growing set of channels.

Instead, the Lightning Network allows us to trustlessly route payments through other nodes in the network. If Alice wants to pay Carol, Alice doesn't need to be directly connected to Carol. Alice can pay Bob and Bob can pay Carol. However, Alice must _know_ that she can pay through Bob.

> The prerequisite for routed payments is that you need an understanding of the paths that a payment can take.

Without this understanding we cannot construct a route to make our payment.

Conceptually we can think of the nodes and channels topology as a graph data structure. Each computer running Lightning Network software is a node in the graph. Each node is uniquely identified by a public key. The edges of the graph are the _public_ channels that exist between nodes. The channels are uniquely identified by the UTXO of the channel's funding transaction.

One consideration is that there is no such thing as a complete picture of the Lightning Network. The Lightning Network allows for private channels between nodes. Only nodes participating in a private channel will see these edges in their view of the network. As a result, the Lightning Network is much larger than the topology created by public channels alone.

Another observation is that we often see visuals of the Lightning Network as an undirected graph. This makes sense when we are trying to get a picture of what channels exist. However there are complications when routing payments. Some balance of funds can exist on either side of the channel. This means that our ability to route through a channel is actually directional. For practical and privacy purposes, the balance on each side of the channel is opaque.

This is a lot to unpack, but if you're curious and want to dig deeper into how node's gossip about the topology and how they perform route path finding, refer to Chapters 11 and 12 in _Mastering the Lightning Network_ by Antonopoulos et al.

For this visualization we'll be treating the graph as undirected. So without further ado, let's get started building!
