# Loop-Out from a Lightning Network Channel

In this section we'll discuss loop-out of funds from a Lightning Network channel using [hold invoices](./hold_invoices.md). A loop-out is the ability to move funds from an off-chain Lightning Network channel to an off-chain address in a trustless way.

An obvious use case for this is a merchant that a receives a large inflow of payments. At a certain point the merchant channel's inbound capacity will be exhausted and the merchant will have a large amount of outbound capacity. A loop-out allows the merchant to simultaneously change the balance of their channel so that they once again have inbound capacity and move the funds to an on-chain address for safe keeping!

This article is going to show to build a simple loop-out service. There are a lot of moving pieces and we need to have on-chain wallet capabilities. In order to keep this article somewhat brief we'll forgo building a fully complete and secure loop-out service and instead work through the mechanics.

## Mechanics of Loop-Out

Each loop-out will generate at least one on-chain transaction, so we need to be mindful of its usage. Performing a loop-out require a service that bridges off-chain Lightning Network payments to on-chain transaction. Functionally the service will broadcast an on-chain HTLC that can be claimed with the hash preimage by the person requesting the loop-out.

So here are the steps for a loop-out between Alice and Bob. Bob runs a loop-out service and Alice wants to migrate some funds on-chain.

1. Alice generates a hash preimage that only she knows
1. Alice provides the hash, a payment address, and the amount to Bob
1. Bob generates a hold invoice and provides the payment request and his payment address to Alice
1. Alice pays the invoice
1. Bob, upon acceptance of the payment, broadcasts an on-chain HTLC that pays Alice if she provides the preimage or it pays him after some timeout period
1. Alice claims the HTLC by spending it using the preimage (Alice now has her funds offline)
1. Bob extracts the preimage from the Alice's claim transaction
1. Bob settles the inbound Lightning payment (Bob now has funds in his LN channel)

Astute readers will recognize that the on-chain HTLC aspect is remarkably similar to how Lightning Network channels make claims against HTLCs when a channel goes on-chain. Typically, when a channel is dropped on-chain it means that the current state of the channel as represented by the commitment transaction is broadcast on-chain. The outputs of this transaction are split between the two participants and any HTLCs that are pending. In order to settle the HTLC outputs one of two things happens:

1. the offerer of an HTLC has access to reclaim the funds after some timeout period
1. the recipient of an HTLC can claim the funds using the preimage

With looping it's much simpler than inside a channel. In our example, Alice can claim the on-chain HTLC using the preimage that she knows. If she does this, then Bob can extract the preimage and settle the off-chain HTLC so that he doesn't lose funds.

One final note is that just like off-chain payments, to ensure there are no funds lost, the timeouts must be larger for incoming HTLCs than the corresponding outgoing HTLC. This ensures that an outgoing HTLC is always fully resolve before the incoming HTLC can be timed out.

## Environment Setup

## Building a Loop-Out Client

The first step is going to be building a client for Alice. To make our lives easier this client will connect to the service over HTTP to exchange necessary information.

The code for our client application can be found in [`exercises/loop-out/client/Client.ts`](https://github.com/bmancini55/building-lightning-advanced/blob/main/exercises/loop-out/client/Client.ts). The start of this file contains a few boilerplate things that must be setup:

1. Connect to our Lightning Network node (we use LND again for this example)
2. Connect to our `bitcoind` node
3. Construct a blockchain monitor that will notify our application when blocks are connected
4. Construct a wallet for storing our keys

After this boilerplate, our application needs to generate the information needed by the loop-out service. In this application we'll use `@node-lightning/bitcoin` library to perform basic Bitcoin functionality. We'll use our wallet to create a new private key. We'll share this with the service using a P2WPKH address.

```typescript
const htlcClaimPrivKey = wallet.createKey();
const htlcClaimPubKey = htlcClaimPrivKey.toPubKey(true);
const htlcClaimAddress = htlcClaimPubKey.toP2wpkhAddress();
logger.info("generated claim address", htlcClaimAddress);
```

_Note_: Why are we using a P2WPKH address instead of a 33-byte public key directly? We could send a 33-byte compressed pubkey, a 20-byte pubkeyhash, or a Bitcoin address (an encoded pubkeyhash). Since we'll be sharing these values over HTTP JSON addresses provide the least ambiguity as to the meaning of the data.

Net we'll create a random preimage and the hash defined as `sha256(preimage)`. The hash will be used in the invoice and the HTLC construction.

```typescript
const preimage = crypto.randomBytes(32);
logger.info("generated preimage", preimage.toString("hex"));

const hash = sha256(preimage);
logger.info("generated hash", hash.toString("hex"));
```

With that information we'll make a simple HTTP request to the service:

```typescript
const apiRequest: Api.LoopOutRequest = {
  htlcClaimAddress: htlcClaimAddress,
  hash: hash.toString("hex"),
  loopOutSats: Number(htlcValue.sats),
};
```

When executed will look something like

```
{
  "htlcClaimAddress": "bcrt1qsnaz83m800prgcgp2dxvv5f9z2x4f5lasfekj9",
  "hash": "c8df085d2d3103e944b62d20fe6c59e117ffec97443f76581434e0ea0af9d7ea",
  "loopOutSats": 10000
}
```

We make the web request

```typescript
const apiResponse: Api.LoopOutResponse = await Http.post<Api.LoopOutResponse>(
  "http://127.0.0.1:1008/api/loop/out",
  apiRequest
);
```

The response will contain a Lightning Network payment request and the refund address owned by the service in case we fail to fulfill the on-chain HTLC in time. We now have everything we need to reconstruct the on-chain HTLC.

A sample response looks like:

```
{
  "htlcRefundAddress": "bcrt1qgmv0jaj36y8v0mlepswd799sf9q7tparlgphe2",
  "paymentRequest": "lnbcrt110u1p3j8ydrpp5er0sshfdxyp7j39k95s0umzeuytllmyhgslhvkq5xnsw5zhe6l4qdqqcqzpgsp55wn3hnhdn3sp4av8t7x5qfpvy4vsdgpyqg6az7gy7fqfg75j49aq9qyyssqpgsjc2y7wvdh7gvg4kyp8lnsv5hgzr0r3xyw0rfydyue9he40wfxzxnp0rcm2lge5qv8hrhfs7j6ecq9r6djwu8z3vuzpqr306g790qqh5kejs"
}
```

We can then use the [`sendPaymentV2`](https://api.lightning.community/#sendpaymentv2) method of LND to pay the payment request.

```typescript
await lightning.sendPaymentV2(
  { payment_request: apiResponse.paymentRequest, timeout_seconds: 600 },
  (invoice) => {
    logger.info("invoice status is now:" + invoice.status);
  }
);
```

However! Before we make the payment request we want start watching the blockchain for the HTLC. To watch for the HTLC we need to look for a transaction that has a P2WSH output matching our HTLC. Recall that P2WSH outputs use Script that is `0x00+sha256(script)`. Only when the output is spent is the script revealed as part of the witness. So for our purposes we want to construct the HTLC Script but then convert it into a P2WSH ScriptPubKey.

Constructing the script uses the [`createHtlcDescriptor`](https://github.com/bmancini55/building-lightning-advanced/blob/main/exercises/loop-out/CreateHtlcDescriptor.ts) method which generates a Script that looks like:

```
OP_SHA256
<32-byte hash>
OP_EQUAL
OP_IF
    OP_DUP
    OP_HASH160
    <20-byte claim pubkeyhash>
OP_ELSE
    28
    OP_CHECKSEQUENCEVERIFY
    OP_DROP
    OP_DUP
    OP_HASH160
    <20-byte refund pubkeyhash>
OP_ENDIF
OP_EQUALVERIFY
OP_CHECKSIG
```

We are going to use the `pubkeyhash` construction inside our HTLCs as defined in [BIP199](https://github.com/bitcoin/bips/blob/master/bip-0199.mediawiki). This saves us 21-bytes compared to using 33-byte public keys and `OP_CHECKSIG`. Also if you recall from above where the client and server exchange information, this is why we can use Bitcoin P2WPKH addresses instead of sharing public keys.

Now that we have the HTLC script, we'll perform a sha256 on this script to convert it into the P2WSH ScriptPubKey. We'll serialize it to a hex string for simple comparison when we receive a block.

```typescript
const htlcScriptPubKeyHex = Bitcoin.Script.p2wshLock(htlcDescriptor)
  .serializeCmds()
  .toString("hex");
```

The result will look like:

```
00<32-byte sha256(htlc_script)>
```

Now that we know what to watch for, we can start watching blocks. To do this we use the [`BlockMonitor`](https://github.com/bmancini55/building-lightning-advanced/blob/main/exercises/loop-out/BlockMonitor.ts) type which allows us to scan and monitor the blockchain.

```typescript
monitor.addConnectedHandler(async (block: Bitcoind.Block) => {
  for (const tx of block.tx) {
    for (const vout of tx.vout) {
      if (vout.scriptPubKey.hex === htlcScriptPubKeyHex) {
        // Upon finding the HTLC on-chain, we will now generate
        // a claim transaction
        logger.info("found on-chain HTLC, broadcasting claim transaction");
        const claimTx = createClaimTx(
          htlcDescriptor,
          preimage,
          htlcClaimPrivKey,
          htlcValue,
          `${tx.txid}:${vout.n}`
        );

        // Broadcast the claim transaction
        logger.debug("broadcasting claim transaction", claimTx.toHex());
        await wallet.sendTx(claimTx);
      }
    }
  }
});
```

The above code attaches a handler function that is executed for each block. We check each output by looking at the `scriptPubKey`. If it matches the previously computed `scriptPubKeyHex` of our HTLC then we have found the HTLC!

When we see the HTLC on-chain, we construct our claim transaction using the [`createClaimTx`](https://github.com/bmancini55/building-lightning-advanced/blob/main/exercises/loop-out/client/CreateClaimTx.ts) method. The claim transaction is defined as:

- version: 2
- locktime: 0xffffffff
- txin count: 1
  - `txin[0]` outpoint: `txid` and `output_index` of the on-chain HTLC
  - `txin[0]` sequence: 0xffffffff
  - `txin[0]` scriptSig bytes: 0
  - `txin[0]` witness: `<claim_signature> <claim_pubkey> <preimage> <htlc_script>`
- txout count: 1
  - `txout[0]` value: `htlc_amount` less `fee` (fee currently fixed at 1sat/byte = 141)
  - `txout[0]` scriptPubKey : `00<20-byte claim pubkey hash>`

We broadcast our claim transaction and our mission is complete! We have successfully moved funds from our Lightning Network channel to our claim pubkey address.

Next we'll take a look at the service.

## Building a Loop-Out Service

The service piece is a bit more complicated.

Our [entrypoint](https://github.com/bmancini55/building-lightning-advanced/blob/main/exercises/loop-out/service/Service.ts) of the service includes some boilerplate to connect to our LND node, conenct to bitcoind, and start an API.

Another thing that happens at the entry point is that our service adds funds to our wallet using the [`fundTestWallet`](https://github.com/bmancini55/building-lightning-advanced/blob/9529d8b39f2d4591d09d717d5d410d76255b7c85/exercises/loop-out/Wallet.ts#L36) method. These funds will be be spent to the on-chain HTLC that the service will create after we receive an incoming hold invoice.

Once we have some funds ready to go we can start our [API](https://github.com/bmancini55/building-lightning-advanced/blob/main/exercises/loop-out/service/Api.ts) and listen for requests. The API simply translates those requests from JSON and supplies the resulting request object into the [`RequestManager`](https://github.com/bmancini55/building-lightning-advanced/blob/main/exercises/loop-out/service/RequestManager.ts) which is responsible for translating events into changes for a request.

Let's now work our way through the service and discuss what happens.

When a request first comes in our we do a few things in the [`addRequest`](https://github.com/bmancini55/building-lightning-advanced/blob/3d0a5c67d1b9fe6676c8e3cc5f0051873a40af14/exercises/loop-out/service/RequestManager.ts#L41) method of the `RequestManager`.

1. Create a new key for the timeout path of our on-chain HTLC
1. Generate a hold invoice payment request that is for the requested amount + fees we want to charge for looping-out.
1. Start watching for changes to the invoice.

At this point the service can send back the payment request an the refund address we just created.

Our request is now `awaiting_incoming_htlc_acceptance`, meaning we are waiting for the requestor to pay the invoice before we broadcast the on-chain HTLC.

When the requestor finally pays the invoice our service will be notified that the LN payment has been accepted. This will trigger the [`onHtlcAccepted`](https://github.com/bmancini55/building-lightning-advanced/blob/3d0a5c67d1b9fe6676c8e3cc5f0051873a40af14/exercises/loop-out/service/RequestManager.ts#L81) method of the `RequestManager`. This method will construct and broadcast our HTLC transaction.

To construct the the HTLC transaction we use [`createHtlcTx`](https://github.com/bmancini55/building-lightning-advanced/blob/864031f737e66ac73c3f19dddc06245166a316c1/exercises/loop-out/service/RequestManager.ts#L181) method. The transaction is constructed according to the following:

- version: 2
- locktime: 0xffffffff
- txin count: 1
  - `txin[0]` outpoint: some available UTXO from our wallet
  - `txin[0]` sequence: 0xffffffff
  - `txin[0]` scriptSig bytes: 0
  - `txid[0]` witness: standard p2wpkh spend
- txout count: 2
  - `txout[0]` value: `htlc_amount` less `service_fee` (cost to loop out is set at 1000 sats)
  - `txout[0]` scriptPubKey : `00<32-byte sha256(htlc_script)>`
  - `txout[1]` value: change amount
  - `txout[1]` scriptPubKey: p2wpkh change address

As we discussed in the previous section our transaction will contain one P2WSH output with the HTLC script. It pays out the amount specified in the loop-out request less the fees we use for service. Recall that the script we use for this is:

```
OP_SHA256
<32-byte hash>
OP_EQUAL
OP_IF
    OP_DUP
    OP_HASH160
    <20-byte claim pubkeyhash>
OP_ELSE
    28
    OP_CHECKSEQUENCEVERIFY
    OP_DROP
    OP_DUP
    OP_HASH160
    <20-byte refund pubkeyhash>
OP_ENDIF
OP_EQUALVERIFY
OP_CHECKSIG
```

The input and second change output are generated by our [wallet software](https://github.com/bmancini55/building-lightning-advanced/blob/3d0a5c67d1b9fe6676c8e3cc5f0051873a40af14/exercises/loop-out/Wallet.ts#L112). The wallet is capable of finding a spendable UTXO and manages adding a change address. This method is a simplification, but our loop-out service would also need to aware of whether funds were available to perform the on-chain transaction. We simplify it by always funding the wallet and assuming we have access to the funds.

After the HTLC transaction is constructed we broadcast it.

Our request is now in the `awaiting_onchain_htlc_claim` state. We are waiting for the requestor to claim the HTLC by spending it using the preimage path. In order to determine if the HTLC has been spent we use the block monitor to watch for spends out of HTLC outpoint. We do this with the [`checkBlockForSettlement`](https://github.com/bmancini55/building-lightning-advanced/blob/3d0a5c67d1b9fe6676c8e3cc5f0051873a40af14/exercises/loop-out/service/RequestManager.ts#L129) method of the `RequestManager`:

```typescript
protected async checkBlockForSettlements(block: Bitcoind.Block): Promise<void> {
    for (const tx of block.tx) {
        for (const input of tx.vin) {
            // Ignore coinbase transactions
            if (!input.txid) continue;

            // Construct the outpoint used by the input
            const outpoint = new Bitcoin.OutPoint(input.txid, input.vout);

            // Find the request that corresponds to this HTLC spend
            const request = this.requests.find(
                p => p.htlcOutpoint.toString() === outpoint.toString(),
            );

            // If we found a request we can now process the invoice
            if (request) {
                await this.processClaimTransaction(input, request);
            }
        }
    }
}
```

When we find a transaction that spends the HTLC outpoint, it means that the requestor has spent the output using the preimage path. We need to extract the preimage so we can settle the incoming hold invoice. We do this with the [`processClaimTransaction`](https://github.com/bmancini55/building-lightning-advanced/blob/3d0a5c67d1b9fe6676c8e3cc5f0051873a40af14/exercises/loop-out/service/RequestManager.ts#L158) method of the `RequestManager` which simply extracts the preimage from the witness data that was used to claim the HTLC. If you recall from the previous section when the claim transaction is build the witness data used to spend the HTLC UTXO is `[<claim_sig>, <claim_pubkey>, <preimage>, <htlc_script>]`.

```typescript
protected async processClaimTransaction(input: Bitcoind.Input, request: Request) {
    request.logger.info("event: block_connected[htlc_spend]");

    // Extract the preimage from witness data. It will
    // always be the third witness value since the values
    // are [signature, pubkey, preimage]
    const preimage = Buffer.from(input.txinwitness[2], "hex");

    // Using the obtained preimage, settle the invoice so
    // we can receive our funds
    if (preimage.length) {
        request.logger.info("action: settle invoice, preimage=", preimage.toString("hex"));
        await this.invoiceMonitor.settleInvoice(preimage);
    }
}
```

Once the preimage is extracted we finally settle the hold invoice and retrieve our funds!
