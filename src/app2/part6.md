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

## Exercise: Implement `isSettled`

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

## Exercise: Implement `next`

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
