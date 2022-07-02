# `AppController` Class

Now that we have all the component pieces built, we'll turn our attention to the primary logic controller for our application! This resides in the `AppController` class located in `server/domain`. This class is responsible for constructing and maintaining the chain of ownership based on received invoices.

The constructor of this class takes a few things we've previously worked on such as:

- `IInvoiceDataMapper` - we'll use this to create and fetch invoices from our Lightning Network node
- `IMessageSigner` - we'll use this validate signatures that we receive from remote nodes
- `LinkFactory` - we'll use this to create links in our ownership chain

If you take a look at this class, you'll also notice that we have the `chain` property that maintains the list of `Link`s in our application. This is where our application state will be retained in memory.

```typescript
public chain: Link[];
```

There is also a conveniently added `chaintip` property that returns the last record in the chain.

```typescript
public get chainTip(): Link {
    return this.chain[this.chain.length - 1];
}
```

One other note about our `AppController` is that it uses the `observer` pattern to notify a subscriber about changes to `Link`s in the chain. The observer will receive an array of `Link` whenever any changes occur to the chain. The observer will first need to assign a handler to `AppController.listener` in order to receive updates. We'll get to this in a future section once everything has been coded.

Dev Note: Why not use `EventEmitter`? Well we certainly could. Since this example only has a single event it's easy to bake in a handler/callback function for `Link` change events.

## Start

We should now have a general understanding of the `AppController` class. You may be wondering how we use it. A great place to begin is how we start the application. We do this with the `start` method. This method is used to bootstrap our application under two start up scenarios:

1. The first time the application is started
1. Subsequent restarts when we have some links in the chain

In either case, we need to get the application state synchronized so we can continue the game.

To do this do two things:

1. Create the first link from the seed
1. Synchronize the application by looking at all of the invoices using `IInvoiceDataMapper`

Back when we discussed the `IInvoiceDataMapper` we had a `sync` method. If you recall, this method accepted an `InvoiceHandler` that looked like this type:

```typescript
export type InvoiceHandler = (invoice: Invoice) => Promise<void>;
```

If you take a look at the `AppController`. You'll see that `handleInvoice` matches this signature! This is not a coincidence. We'll we use `handleInvoice` method to process invoices from our Lightning Network node.

Now that we understand that, let's do an exercise and implement our `start` method then we'll implement `handleInvoice.

## Exercise: Implement `start`

To implement that method requires us to perform two tasks:

1. Use the `linkFactory` to create the first `Link` from the seed argument
1. Once the first link is created, initiate the synchronization of invoices using the `IInvoiceDataMapper` (as mentioned, provide the `AppController.handleInvoice` method as the handler).

```typescript
public async start(seed: string, startSats: number) {
    // Exercise
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep AppController.*start
```

## Exercise: Implement `handleInvoice`

Next on the docket, we need to process invoices we receive from our Lightning Network node. The `handleInvoice` is called every time an invoice is created or fulfilled by our Lightning Network node. This method does a few things to correctly process an invoice:

1. checks if the invoice settles the current chain tip. Hint look at the `settles` method on the `Invoice`. If the invoice doesn't settle the current chaintip, no further action is required.
1. If the invoice does settle the current chaintip, it should call the `settle` method on `Link` to settle the `Link`.
1. It should then create a new `Link` using the `LinkFactory.createFromSettled`.
1. It should add the new unsettled link to the chain
1. Finally, it will send the settled link and the new link to the listener.

This method is partially implemented for you. Complete the method by settling the current link and constructing the next link from the settled link.

```typescript
public async handleInvoice(invoice: Invoice) {
    if (invoice.settles(this.chainTip)) {
        // settle the current chain tip
        const settled = this.chainTip;

        // create a new unsettled Link

        // add the new link to the chain

        // send settled and new to the listener
        if (this.listener) {
            this.listener([settled, nextLink]);
        }
    }
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep AppController.*handleInvoice
```

## Exercise: `createInvoice`

The last bit of code `AppController` is responsible for is creating invoices. This method is responsible for interacting with the Lightning Network node's message signature verification through the `IMessageSigner` interface. It will also interact with the Lightning Network node to create the invoice via the `IInvoiceDataMapper`.

Recall that when someone wants to take ownership of the current link they'll need to send a digital signature of the last revealed preimage.

Our method does a few things:

1. Verifies the signature is for the current `chaintip`. If not, it returns a failure.
1. Constructs the preimage for the invoice. Recall that we implemented the `createPreimage` method on `Invoice` previously.
1. Constructs the memo for the invoice. Recall that we implemented the `createMemo` method on `Invoice` previously.
1. Creates the invoice using the `IInvoiceDataMapper`
1. Return success or failure result depending on the result

This method is partially implemented for you.

```typescript
public async createInvoice(
    remoteSignature: string,
    sats: number,
): Promise<CreateInvoiceResult> {
    // verify the invoice provided by the user
    const verification = await this.signer.verify(this.chainTip.priorPreimage, remoteSignature);

    // return failure if signature fails
    if (!verification.valid) {
        return { success: false, error: "Invalid signature" };
    }

    // Exercise: create the preimage

    // Exercise: create the memo

    // try to create the invoice
    try {
        const paymentRequest = await this.invoiceDataMapper.add(sats, memo, preimage);
        return {
            success: true,
            paymentRequest,
        };
    } catch (ex) {
        return {
            success: false,
            error: ex.message,
        };
    }
}

```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep AppController.*createInvoice
```
