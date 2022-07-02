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

## Exercise: Implement `createMemo`

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

## Exercise: Implement `isAppInvoice`.

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

## Exercise Implement `priorPreimage` and `buyerNodeId`

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

## Exercise: Implement `createPreimage`

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
