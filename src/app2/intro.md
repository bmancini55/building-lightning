# Building on Lightning: Working with Invoices

Now that you've become familiar with connecting to a Lightning Network node, we will create a new application that leverages the power of invoices.

Invoices are the Lightning Network's mechanism for requesting payments. The standard flow works by the payee (eg: an online retailer) generating an invoice for a specific amount. This invoice contains a hash of some value that only the payee knows. Upon receipt of payment, the payee release the preimage of the hash. Knowledge of the preimage acts as a receipt of payment (there is no way to guess the preimage without being given it).

# Goal of the Application

This application is going to use the Lightning Network to create a virtual game of "king of the hill". In this game you become the leader by paying an invoice. Someone else can be the new leader by paying an invoice for more than you paid and so on.

So for instance if Alice is the first leader for 1000 satoshis. Bob can pay an invoice for 1001 satoshis and become the leader.

The neat thing is that we'll do this in a way that Bob can cryptographically prove that paid to be the leader over Alice.

This construct is the beginning of a protocol that could be used for more advanced provenance of digital assets, or for something entirely unrelated.

The main goal of this is to show how to build an application entirely using invoices and a node's invoice database.

# Cryptographic Primitives

This application uses hashes and digital signatures. We'll briefly perform a review, but you are encouraged to fully understand both of these method through self-study

## Hashing

Hashes are a one-way function. The input to the function is known as a preimage. When the preimage is run through the hash function it produces a digest. Hash functions are cryptographically secure when the digest is indistinguishable from random. More simply, this means that there are no discernable patterns produced by the hash function. Additionally, when we say that a hash is a one-way function it means that given the digest, there is no way we can determine the preimage.

For example, if we use the SHA-256 hash algorithm:

sha256("a") = ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb
sha256("b") = 3e23e8160039594a33894f6564e1b1348bbd7a0088d42c4acb73eeaed59c009d
sha256("ab") = fb8e20fc2e4c3f248c60c39bd652f3c1347298bb977b8b4d5903b85055620603

There is no way to derive (other than brute force) that the hash for "ab" is derived from the concatenation of "a" and "b".

## ECDSA

This application will also make use of digital signatures created with the elliptic curve digital signature algorithm.

Digital signatures are created by a using a private key to sign a message. The resulting signature can be verified by anyone with the message. The neat aspect of digital signatures is that the signature can't be forged. Given a message, only the holder of the public key can create the signature.

If you are provided with the a public key, you can verify that the signature was signed by the owner of the public key.

With the signature, you can also derive the public key that was used to create the signature. When verifying a signature, Lightning Network nodes will derive the public key and check it against the database in the network graph.

# High Level Overview of Our Application

So let's talk about our application! We're going to use a combination of digital signatures and hashing to create an ownership chain.

The basis of this chain is that the preimage from the last-settled invoice becomes the information that is signed to create the next preimage. In a sense this creates a hash-chain of ownership.

For example, consider if Alice is running the server for our application. She initiates the service with some `seed` value. Alice then signs a message with the `seed` and keeps her signature to herself for now. Alice can always easily re-derive this signature if she needs to by resigning the `seed`.

Bob accesses Alice's service, and discovers that he can "own" the `seed` by

1. Creating a signature where the message is the `seed`
1. Sending Alice the signature

Alice then verifies the signature for the `seed` from Bob.

Alice can now create a preimage for an invoice by concatenating Alice's signature for the seed, Bob's signature for the seed, and the satoshis that Bob is willing to pay.

```
alice_sig(seed) || bob_sig(seed) || satoshis
```

The only issue is that Lightning Network invoices require the preimage to be 32-bytes. We get around this by simply using hashing to contain the value within 32-bytes:

```
sha256(alice_sig(seed) || bob_sig(seed) || satoshis)
```

Thus our hash for the invoice is the hash of the preimage:

```
sha256(sha256(alice_sig(seed) || bob_sig(seed) || satoshis))
```

Alice now has a preimage that she can use for an invoice. She sends this invoice to Bob. Bob wants to take ownership, so he pays the invoice and receives the preimage.

At this point, Bob can prove that he paid for it, but he can't quite prove to the entire world that he is the owner.

When Alice receives payment, she needs to publish her signature for the seed as well.

Bob now has his signature and Alice's signature and can reconstruct the preimage at will to prove that is the rightful owner of the current seed.

This is all well and good, but how does Carol take over ownership? In order to do this, Alice signs the preimage she just sent to Bob. She advertises Bob's preimage as well. Carol can sign Bob's preimage and perform the same functionality as Bob.

Now that may be a lot to unpack, so you may want to go through it a few time. And don't worry, if you don't [grok](https://www.merriam-webster.com/dictionary/grok) the concept completely you'll still be able to build the application. After a few goes at making Alice, Bob, and Carol the leader it will hopefully become more intuitive.

# Building the Application

The application uses the same template we used in Graph exercise, so you should already be familiar with the structure. As a quick refresher. For this application we'll be focused on building logic inside the `server` sub-project.

The application code is available in the [Building on Lightning Invoices Project](https://github.com/bmancini55/building-lightning-invoices) on GitHub. You can clone this repository to begin.

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

We'll also need a Lightning Network environment to test. You can use the existing environment you created with Polar in the first project. We'll again be building the application from the perspective of Alice using an LND node.

## Exercise: Configuring `.env` to Connect to LND

We'll again use the `dotenv` package to simplify environment variables.

Our next exercise is adding some values to `.env` inside the `server` sub-project. We'll add three new environment variables:

- `LND_RPC_HOST` is the host for LND RPC
- `LND_ADMIN_MACAROON_PATH` is the file path to the admin Macaroon
- `LND_CERT_PATH` is the certificate we use to securely connect with LND

In Polar, to access Alice's node by click on Alice and then click on the `Connect` tab. You will be shown the information on how to connect to the GRPC and REST interfaces. Additionally you will be given paths to the network certificates and macaroon files that we will need in `.env`.

![Connect to Alice](../images/ch1_polar_connect_to_alice.png)

Go ahead and add the three environment variables defined above to `.env`.

```
# Express configuration
PORT=8001

# LND configuration
# Exercise: Provide values for Alice's node
LND_RPC_HOST=
LND_ADMIN_MACAROON_PATH=
LND_CERT_PATH=
```

# Invoices

The next logical step is configuring how we'll handle invoices. For this application, we'll use LND and its invoice database to power our application. We'll be encoding some basic information into the invoice memo field so our application doesn't need to maintain or synchronize a separate database. In a production system we'd likely use a separate database system, but we've made this decision to keep the application tightly focused.

This time around we'll be using the [LND RPC API](https://api.lightning.community/#lnd-grpc-api-reference). This is similar to the REST interface we used in the previous application but uses a GRPC instead of HTTPS to communicate with the LND node. For the purposes of our application it will be remarkably similar and in reality, the only difference will be how we wire up the application. Which brings us to our next point.

From a software engineering perspective, it's a good practice to isolate our application logic from the specifics of the underlying data persistence mechanism. This rule is often conveyed when working with relational databases systems where it would be poor form for your database tables to dictate how your application logic functions. This is no different than working with Lightning Network nodes! We break out our code so that we can tightly focus the critical application bits from the logic of how we retrieve that information. A by-product is that we could switch out from LND to c-lightning or Eclair without having to change our application's logic!

To achieve this decoupling goal, instead of pinning our application to the structure of invoices in LND's database, we'll create our own `Invoice` type that is used throughout our application. This also allows us to add some methods or calculations to our `Invoice` type that are "domain" specific to our application.

You can take a look at the `server/domain/Invoice` class. This class only has properties that the application is interested in such as the memo, preimage, hash, value in satoshis, and settlement information.

```typescript
export class Invoice {
  constructor(
    public memo: string,
    public preimage: string,
    public hash: string,
    public valueSat: string,
    public settled: boolean = false,
    public settleDate?: number
  ) {}

  // Methods not shown...
}
```

# Exercise: Implement `createMemo`

Our application is going be encoding some information into the memo field. We need to be careful about making the memo field too large but for our applications sake we'll construct the memo as such:

```
buy_{preimage}_{buyerId}
```

The `preimage` is going to 32-byte value (64 hex encoded characters). The `buyerId` is the 33-byte public key (66 hex encoded characters) of the buying node.

Go ahead and implement the `createMemo` method in `server/domain/Invoice` class according to the rule specified

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep createMemo
```

# Exercise: Implement `isAppInvoice`.

We need a way to distinguish invoices that the application cares about from other invoices that the Lightning Network node may have created for other purpose.

We'll do this by implementing the `isAppInvoice` method to check whether the memo conforms to the pattern we just created in the `createMemo` method.

We will only return true when a few conditions have been met:

1. The invoice's memo field starts with the prefix `buy_`
1. The invoice's memo then contains 64 hex characters followed by another underscore
1. The invoice's memo ends with 66 hex characters.

Go ahead and implement the `isAppInvoice` in the `server/domain/Invoice` class.

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep isAppInvoice
```

# Exercise Implement `priorPreimage` and `buyerNodeId`

We have two more helper methods we need to implement surrounding the memo field. We want a quick way to extract the prior preimage and the buyer's public key. We'll do this by implementing two helper methods that grab these values from the memo field. These two methods are very similar, so feel free to be creative in how you structure your code (and possibly refactor the `isAppInvoice` method).

Go ahead and implement the `priorPreimage` getter in the `server/domain/Invoice` class.

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep priorPreimage
```

Then go ahead and implement the `buyerNodeId` getter in the `server/domain/Invoice` class.

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep buyerNodeId
```

# Exercise: Implement `createPreimage`

The last method we'll implement is a helper method that we will use later. If you recall that we're going to calculate the preimage as:

```
sha256(alice_sig(seed) || bob_sig(seed) || satoshis)
```

where `||` denotes concatenation.

Based on that information, go ahead and implement the `createPreimage` method in the `server/domain/Invoice` class.

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep createPreimage
```

# Loading Invoices

Now that we've discussed some aspects of domain specific invoices, we need to connect to some Lightning Network node and load up invoices from its database. Our application does this using the [data mapper](https://martinfowler.com/eaaCatalog/dataMapper.html) design pattern to abstract specifics about data access.

We define this behavior in the `IInvoiceDataMapper` interface that looks like:

```typescript
export interface IInvoiceDataMapper {
  add(value: number, memo: string, preimage: Buffer): Promise<string>;
  sync(): Promise<void>;
}
```

For loading invoices we're concerned with the `sync` method.

The `sync` method reaches out to our invoice database and requests all invoices. It will also subscribe to creation of new invoices or the settlement of existing invoices. Because the syncing process and the subscription are long lived, we will use notification to alert our application code about invoice events instead of returning a list of `Invoice`s.

The `LndInvoiceDataMapper` class implements `IInvoiceDataMapper` and is located in `server/data/lnd` folder. This constructor of this class accepts an interface `ILndClient` that defines functions for interacting with an LND node.

There are two classes that implement `ILndClient`: `LndRestClient` and `LndRpcClient` that connect to LND over REST and GRPC. We'll be using the latter to connect to LND over the GRPC API. For the purposes of our application, either client could be used. The indication of code isolates our data mapper logic from the logic specific to each of the APIs. This is similar to how our we isolate our application code from the specifics of LND. Feel free to explore the `LndRpcClient` and `LndRestClient` to see how they manage the details of establishing connections to the different APIs.

Dev note: If you take a closer look at `LndInvoiceDataMapper` you may notice that it is not a Nodejs [`EventEmitter`](https://nodejs.dev/learn/the-nodejs-event-emitter). Instead we manually implement the [observer pattern](https://en.wikipedia.org/wiki/Observer_pattern) with the `addHandler` and `notifyHandlers` methods. The reason we don't use EventEmitter is that we want our handler functions to be async and we want notification to block / await completion of the prior handler. This is something to be mindful of when working events and async/await code. They don't always play nice and you may need to make some extra steps to prevent unexpected errors.

The `addHandler` method simply adds a delegate to the class so that the delegate can be called when an invoice is processed. This method allows us to attach some outside observer to the list of invoices that get processed at any time.

The `InvoiceHandler` delegate is just any function that receives an `Invoice` as an argument:

```typescript
export type InvoiceHandler = (invoice: Invoice) => void;
```

The `addHandler` method just adds the handler to a collection.

```typescript
public addHandler(handler: InvoiceHandler) {
    this.handlers.add(handler);
}
```

Once we have some handlers, we can notify them using the `notifyHandlers` method. This method is equally simply in that it just calls the handler with the invoice. The interesting thing here is that this method is `async` and we `await` on execution of each handler to serialization execution.

```typescript
public async notifyHandlers(invoice: Invoice) {
    // emit to all async event handlers
    for (const handler of this.handlers) {
        await handler(invoice);
    }
}
```

If we again put our focus on the `sync` method inside `LndInvoiceDataMapper` we'll see that the method does two things:

1. connects to LND and retrieves all invoices in the database
1. subscribes to existing invoices and

```typescript
public async sync(): Promise<void> {
    // fetch all invoices
    const num_max_invoices = Number.MAX_SAFE_INTEGER.toString();
    const index_offset = "0";
    const results: Lnd.ListInvoiceResponse = await this.client.listInvoices({
        index_offset,
        num_max_invoices,
    });

    // process all retrieved invoices
    for (const invoice of results.invoices) {
        await this.notifyHandlers(this.convertInvoice(invoice));
    }

    // subscribe to all new invoices/settlements
    void this.client.subscribeInvoices(invoice => {
        void this.notifyHandlers(this.convertInvoice(invoice));
    }, {});
}
```

You'll see that we notify handlers of invoices after we call `convertInvoice` on LND's invoice.

# Exercise: Implement `convertInvoice`

This function is a mapping function that converts LND's invoice type in our domain's `Invoice` class.

Go ahead and implement the `convertInvoice` method in the `server/data/LndInvoiceDataMapper` class. Make sure to perform proper type conversions.

```typescript
public convertInvoice(invoice: Lnd.Invoice): Invoice {
    // Exercise: Implement
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep convertInvoice
```

At this point our application has all the necessary pieces to retrieve and process invoices.

# `Link` Class

For our application, we can think of the leadership chain as links in a chain. The last "closed" link in the chain is the current leader. However, by closing a link, we create a new link that is open for someone else to close if they pay an invoice to do so. The last "closed" link the chain is the current leader of the game.

The `Link` class defines a single link in the chain of ownership and it models this behavior of ownership. A `Link` can be in one of two states: `unsettled` or `settled`.

When a `Link` is unsettled, it means that no one has take ownership or closed that link. It is still open to the world and anyone can pay an invoice and take ownership.

When a `Link` is settled, the payer of the invoice becomes the owner. If this is the last closed link in the chain it is considered the current leader of the game.

So let's take a look at the `Link`.

```typescript
export class Link {
  public invoice: Invoice;

  constructor(
    public priorPreimage: string,
    public localSignature: string,
    public minSats: number
  ) {}

  // Methods
}
```

As you can see it's pretty straightforward.

We define a few properties

- `priorPreimage` is the identifier. We "link" back to the last settled invoice by making the `Link` identifier the last settled preimage.
- `localSignature` is our Lightning Network node's signature of the `priorPreimage`. We'll use this to construct invoices.
- `minSats` is the minimum satoshis payment we're willing to accept payment to settle this Link.

You'll also notice that there is an `invoice` property. This property will be assigned a settled invoice when someone pays the `Invoice`.

# Exercise: Implement `isSettled`

A `Link` is only considered settled when it has an invoice assigned and that invoice is settled.

Go ahead and implement the `isSettled` getter.

```typescript
public get isSettled(): boolean {
    // Exercise
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep isSettled
```

# Exercise: Implement `next`

Once a `Link` is settled, the `next` property makes reference to the identifier of the next `Link` in the chain, which is the settled invoice's preimage.

This property should only return a value when a `Link` is settled. When the `Link` is settled it should return the invoice's preimage.

Go ahead and implement the `next` getter.

```typescript
public get next(): string {
    // Exercise
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep next
```

# `LinkFactory` Class

So you may be wondering how we create our first `Link`. Let us introduce you to the the `LinkFactory`. This class is responsible for creating `Link` object based on two common scenarios:

1. `createFromSeed` - creates the first link in the chain
1. `createFromSettled` - creates a new "tip of the chain" link when someone closes / settles a Link

This class also takes care of the heavy lifting for creating a `Link` so that we can easily test our code, and consumers of this code aren't burdened by the implementation details of creating a `Link`.

This class has a dependency on the `IMessageSigner` interface. This interface provides a method for signing a message from your Lightning Network node.

```typescript
export interface IMessageSigner {
  sign(msg: string): Promise<string>;
  verify(msg: Buffer, signature: string): Promise<VerifySignatureResult>;
}
```

Under the covers, we have also implemented a `LndMessageSigner` class that uses LND to perform signature creation and verification. This will be wired up later.

# Exercise: Implement `createFromSeed`

As we mentioned, a `Link` starts out in the `unsettled` state, which means that no one has taken ownership of it. Logically, the application starts off without any ownership. We simply create a link from some seed value.

In order to create a link we do two things:

1. Sign the seed value
1. Construct a new `Link` with the seed, signature, and minimum satoshis values

Go ahead and implement the `createFromSeed` method.

```typescript
public async createFromSeed(seed: string, startSats: number): Promise<Link> {
    // Exercise
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep createFromSeed
```

# Exercise: Implement `createFromSettled`

The next logical piece is implementing the `createFromSettled` method which will create the next `unsettled` link from a `settled` link.

Instead of a seed, we'll use the preimage from the settled invoice of the prior Link. This method will need to do three things:

1. Use the `IMessageSigner.sign` method to sign the preimage
1. Increment the minimum satoshis to +1 more than the settled invoice
1. Construct the new `unsettled` `Link`

Go ahead and implement the `createFromSettled` method.

```typescript
public async createFromSettled(settled: Link): Promise<Link> {
    // Exercise
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep createFromSettled
```

# `AppController` Class

Now that we have all the component pieces built, we'll turn our attention to the primary logic controller for our application! This resides in the `AppController` class located in `server/domain`. This class is responsible for constructing and maintaining the chain of ownership based on received invoices.

# Putting It All Together
