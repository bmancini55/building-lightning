# Creating the `LinkFactory` Class

To help us construct links we'll use the `LinkFactory` class. This class is responsible for creating `Link` object based on two common scenarios:

1. `createFromSeed` - creates the first link in the chain
1. `createFromSettled` - creates a new "tip of the chain" link when someone closes / settles a Link

This class also takes care of the heavy lifting for creating a `Link` so that we can easily test our code, and consumers of this code aren't burdened by the implementation details of creating a `Link`.

This class has a dependency on the `IMessageSigner` interface. This interface provides a method for signing a message using your Lightning Network node.

```typescript
export interface IMessageSigner {
  sign(msg: string): Promise<string>;
  verify(msg: Buffer, signature: string): Promise<VerifySignatureResult>;
}
```

Under the covers, we have also implemented a `LndMessageSigner` class that uses LND to perform signature creation and verification. This will be wired up later but feel free to explore this code in the `server/data/lnd` folder.

## Exercise: Implement `createFromSeed`

As we previously discussed, a `Link` starts out in the `unsettled` state, which means that no one has taken ownership of it. Logically, the application starts off without any ownership. We simply create a link from some seed value.

In order to create a link we do two things:

1. Sign the seed value using our `IMessageSigner` instance
1. Construct a new `Link` with the seed, signature, and the minimum satoshis values

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

## Exercise: Implement `createFromSettled`

The next logical piece is implementing the `createFromSettled` method which will create the next `unsettled` link from a `settled` link.

Instead of a seed, we'll use the `next` property from the `Link` which we implemented in the previous section. This method will need to do three things:

1. Use the `IMessageSigner.sign` method to sign the `next` value
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
