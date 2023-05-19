# Creating the `LinkFactory` Class

To help us construct links we'll use the `LinkFactory` class. This class is responsible for creating `Link` objects based on two common scenarios:

1. `createFromSeed` - creates the first link in the chain using a seed since we won't have a prior link.
1. `createFromSettled` - creates a new "tip of the chain" link when someone closes / settles a Link using the last settled link.

This class takes care of the heavy lifting for creating a `Link` so that we can easily test our code, and the consumers of this code aren't burdened by the implementation details of creating a `Link`.

As we previously talked about, we'll be using digital signatures. This class has a dependency on the `IMessageSigner` interface. This interface provides two methods:

1. one for signing a message using your Lightning Network node
1. one for verifying a received signature

```typescript
export interface IMessageSigner {
  /**
   * Signs a message using the Lightning Network node
   */
  sign(msg: string): Promise<string>;

  /**
   * Verifies a message using the Lightning Network node
   */
  verify(msg: Buffer, signature: string): Promise<VerifySignatureResult>;
}
```

Under the covers, we have already implemented a `LndMessageSigner` class that uses LND to perform signature creation and verification. This will be wired up later but feel free to explore this code in the `server/src/data/lnd` folder.

## Exercise: Implement `createFromSeed`

As we previously discussed, a `Link` starts out in the `unsettled` state, which means that no one has taken ownership of it. Logically, the application starts off without any ownership and in an `unsettled` state. Since we don't have any prior links, we'll simply create a link from some seed value.

In order to create a link we do two things:

1. Sign the seed value using our Lightning Network node using the `IMessageSigner` instance.
1. Construct a new `Link` and supply the seed as the `linkId`, the signature our application server made for the seed, and the starting satoshis value required for the first owner.

Go ahead and implement the `createFromSeed` method.

Tip: The `sign` method is a asynchronous so be sure to use it with `await`, for example: `const sig = await this.signer.sign(some_msg)`

```typescript
public async createFromSeed(seed: string, startSats: number): Promise<Link> {
    // Exercise
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep createFromSeed
```

## Exercise: Implement `createFromSettled`

Now that we know how to create a link to start the application. A person could become the leader by paying the invoice. Once that invoice is paid, the first link will become settled. We need a method to create a _new_ link so that the next person can try to become the leader.

We will create the `createFromSettled` method which will create the next `unsettled` link from a link that has been `settled`.

Instead of a seed, we'll use the `nextLinkId` property from the `Link`, which we implemented in the previous section, as the link's identifier.

The `createFromSettled` method will need to do three things:

1. Use the `IMessageSigner.sign` method to sign the `nextLinkId` value using our Lightning Network node
1. Increment the minimum satoshis to +1 more than the settled invoice
1. Construct the new `unsettled` `Link`

Go ahead and implement the `createFromSettled` method.

Dev Tip: You will need to look at the settling invoice satoshi value to determine the next increment. This value is a string, so be sure to cast it to a number with `Number(some_string)`.

```typescript
public async createFromSettled(settled: Link): Promise<Link> {
    // Exercise
}
```

When you are finished you can verify you successfully implemented the method with the following command:

```
npm run test:server -- --grep createFromSettled
```
