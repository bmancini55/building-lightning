# Loading Invoices

Now that we've discussed some aspects of domain specific invoices, we need to connect to some Lightning Network node and load up invoices from its database. Our application does this using the [data mapper](https://martinfowler.com/eaaCatalog/dataMapper.html) design pattern to abstract specifics about data access.

We define this behavior in the `IInvoiceDataMapper` interface that looks like:

```typescript
export interface IInvoiceDataMapper {
  add(value: number, memo: string, preimage: Buffer): Promise<string>;
  sync(handler: InvoiceHandler): Promise<void>;
}
```

The `InvoiceHandler` delegate is just any function that receives an `Invoice` as an argument:

```typescript
export type InvoiceHandler = (invoice: Invoice) => Promise<void>;
```

The `LndInvoiceDataMapper` class implements `IInvoiceDataMapper` and is located in `server/data/lnd` folder. This constructor of this class accepts an interface `ILndClient` that defines functions for interacting with an LND node.

There are two classes that implement `ILndClient`: `LndRestClient` and `LndRpcClient` that connect to LND over REST and GRPC. We'll be using the latter to connect to LND over the GRPC API. For the purposes of our application, either client could be used. The indication of code isolates our data mapper logic from the logic specific to each of the APIs. This is similar to how our we isolate our application code from the specifics of LND. Feel free to explore the `LndRpcClient` and `LndRestClient` to see how they manage the details of establishing connections to the different APIs.

For loading invoices we're concerned with the `sync` method.

The `sync` method reaches out to our invoice database and requests all invoices. It will also subscribe to creation of new invoices or the settlement of existing invoices. Because the syncing process and the subscription are long lived, we will use notification to alert our application code about invoice events instead of returning a list of `Invoice`s.

This method does two things:

1. connects to LND and retrieves all invoices in the database
1. subscribes to existing invoices and

```typescript
public async sync(handler: InvoiceHandler): Promise<void> {
    // fetch all invoices
    const num_max_invoices = Number.MAX_SAFE_INTEGER.toString();
    const index_offset = "0";
    const results: Lnd.ListInvoiceResponse = await this.client.listInvoices({
        index_offset,
        num_max_invoices,
    });

    // process all retrieved invoices
    for (const invoice of results.invoices) {
        await handler(this.convertInvoice(invoice));
    }

    // subscribe to all new invoices/settlements
    void this.client.subscribeInvoices(invoice => {
        void handler(this.convertInvoice(invoice));
    }, {});
}
```

You'll see that we notify handlers of invoices after we call `convertInvoice` on LND's invoice.

## Exercise: Implement `convertInvoice`

This function is a mapping function that converts LND's invoice type in our domain's `Invoice` class.

Go ahead and implement the `convertInvoice` method in the `server/data/LndInvoiceDataMapper` class. Make sure to perform proper type conversions.

```typescript
public convertInvoice(invoice: Lnd.Invoice): Invoice {
    // Exercise
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep convertInvoice
```

At this point our application has all the necessary pieces to retrieve and process invoices.
