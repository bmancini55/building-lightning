# Loading Invoices

Now that we've discussed some aspects of domain specific invoices, we need to connect to our Lightning Network node and load invoices from its database. Our application does this using the [data mapper](https://martinfowler.com/eaaCatalog/dataMapper.html) design pattern to isolate the specifics about data access from the remainder of our application logic.

We define our data access behavior in the `IInvoiceDataMapper` interface that contains two methods for adding an invoice and performing a synchronization with the database.

```typescript
export interface IInvoiceDataMapper {
  /**
   * Adds an invoice to the Lightning Network node
   */
  add(value: number, memo: string, preimage: Buffer): Promise<string>;

  /**
   * Synchronizes the application with the current state of invoices. The
   * handler method will be called for each invoice found in the invoice
   * database and will be called when a new invoice is created, settled,
   * or changes.
   */
  sync(handler: InvoiceHandler): Promise<void>;
}

/**
 * Defines a callback function that can be used to process a found invoice.
 */
export type InvoiceHandler = (invoice: Invoice) => Promise<void>;
```

With the `IInvoiceDataMapper` defined, we need to implement a concrete version of it that works with LND. The `LndInvoiceDataMapper` class does just that. It is located in the `server/data/lnd` folder. The constructor of this class accepts the interface `ILndClient`. There are two classes that implement `ILndClient`: `LndRestClient` and `LndRpcClient` that connect to LND over REST and GRPC respectively. We'll be using the latter to connect to LND over the GRPC API. With this code structure, our application could switch to other types of Lightning Network nodes by implementing a new `IInvoiceDataMapper`. Or if we wanted to switch between the LNDs REST or GRPC client we can supply a different `ILndClient` to the `LndInvoiceDataMapper`.

We'll now explore the methods on the `LndInvoiceDataMapper`. For loading invoices we're concerned with the `sync` method.

The `sync` method reaches out to our invoice database and requests all invoices. It will also subscribe to creation of new invoices or the settlement of existing invoices. Because the syncing process and the subscription are long lived, we will use notifications to alert our application code about invoice events instead of returning a list of the `Invoice` type. You may have noticed the `InvoiceHandler` type. This type defines any function that receives an `Invoice` as an argument. Our `sync` method takes a single argument which must be an `InvoiceHandler`. This handler function will be called every time an invoice of is found or changes.

The `sync` method does two things:

1. connects to LND and retrieves all invoices in the database
1. subscribes to existing invoices for changes

```typescript
public async sync(handler: InvoiceHandler): Promise<void> {
    // fetch all invoices
    const num_max_invoices = Number.MAX_SAFE_INTEGER.toString();
    const index_offset = "0";
    const results: Lnd.ListInvoiceResponse = await this.client.listInvoices({
        index_offset,
        num_max_invoices,
    });

    // process all retrieved invoices by calling the handler
    for (const invoice of results.invoices) {
        await handler(this.convertInvoice(invoice));
    }

    // subscribe to all new invoices/settlements
    void this.client.subscribeInvoices(invoice => {
        void handler(this.convertInvoice(invoice));
    }, {});
}
```

Looking at this code, you'll see that the method receives a `handler: InvoiceHandler` parameter and we call that handler for each invoice that our database returns and when there is a change as a result of the subscription.

But, before we call the handler we need to convert the invoice from LND's invoice to our application's `Invoice` type.

## Exercise: Implement `convertInvoice`

This function is a mapping function that converts LND's invoice type into our application domain's `Invoice` class.

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
