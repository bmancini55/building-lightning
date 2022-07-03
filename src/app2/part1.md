# Application Walk-Through

You've seen the example of our application with Bob and Carol becoming the leaders. This section will dig into the details of how the application works. Before we do that however, we'll do a quick refresher on some cryptographic primitives.

## Cryptographic Hash Function

A cryptographic hash function is a one-way function. The input to the function is known as a preimage. When the preimage is run through the hash function it produces a digest. Hash functions are cryptographically secure when the digest is indistinguishable from random. More simply, this means that there are no discernable patterns produced by the hash function. Additionally, when we say that a hash is a one-way function it means that given the digest, there is no way we can determine the preimage.

For example, if we use the SHA-256 hash algorithm:

sha256("a") = ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb
sha256("b") = 3e23e8160039594a33894f6564e1b1348bbd7a0088d42c4acb73eeaed59c009d
sha256("ab") = fb8e20fc2e4c3f248c60c39bd652f3c1347298bb977b8b4d5903b85055620603

There is no way to derive (other than brute force) that the hash for "ab" is derived from the concatenation of "a" and "b".

## Elliptic Curve Digital Signature Algorithm (ECDSA)

This application will also make use of digital signatures created with the elliptic curve digital signature algorithm.

Digital signatures are created by a using a private key to sign a message. The resulting signature can be verified by anyone with the message. The neat aspect of digital signatures is that the signature can't be forged. Given a message, only the holder of the public key can create the signature.

If you are provided with the a public key, you can verify that the signature was signed by the owner of the public key.

With the signature, you can also derive the public key that was used to create the signature. When verifying a signature, Lightning Network nodes will derive the public key and check it against the database in the network graph.

# Our Algorithm

You've seen the example of our application with Bob and Carol becoming the leaders. This section will dig into the details of how the application works.

In order to create the ownership chain we're going to use a combination of digital signatures and hashes.

The basis of this chain is that the preimage from the last-settled invoice is used as the identifier of the next link. In a sense this creates a hash-chain of ownership.

![Basic Links](/images/ch2_diagram_01.png)

While this diagram is fairly straight forward, the way we construct the actual ownership chain is a bit more complicated. This complication is necessary for a few reasons:

1. Ensures that each invoice in a link has a unique preimage and hash
1. Ensures that it is not possible to guess the preimage for an invoice
1. Ensures that a leader can reconstruct the preimage using information that only they can generate once a payment has been made

So let's explore the actual construct.

Consider if Alice is running the server for our application. She initiates the service with some `seed` value. Alice then signs a message with the `seed` and keeps her signature to herself for now. Alice can always easily re-derive this signature if she needs to by resigning the `seed`.

Bob accesses Alice's service, and discovers that he can "own" the `seed` by

1. Creating a signature where the message is the `seed`
1. Sending Alice the signature

Alice then verifies the signature for the `seed` from Bob. Only Bob will be able to generate this signature, but anyone can verify that the signature is valid.

Alice can now create a preimage for an invoice by concatenating her signature for the seed, Bob's signature for the seed, and the satoshis that Bob is willing to pay.

```
preimage = alice_sig(seed) || bob_sig(seed) || satoshis
```

The only issue is that the Lightning Network invoices require the preimage to be 32-bytes. We get around this by simply using hashing to contain the value within 32-bytes:

```
preimage = sha256(alice_sig(seed) || bob_sig(seed) || satoshis)
```

Then our hash in the invoice is the hash of the preimage:

```
hash = sha256(preimage)
hash = sha256(sha256(alice_sig(seed) || bob_sig(seed) || satoshis))
```

Alice sends Bob the invoice. Bob wants to take ownership, so he pays the invoice and receives the preimage as proof of payment.

At this point, Bob can prove that he paid the invoice since he has the preimage, but he can't reconstruct the preimage. Alice needs to publish her signature to the website for Bob to be able reconstruct the preimage. Ideally we would have a scheme where Bob can prove ownership without needing out-of-band information, something encoded directly in the preimage itself.

So how does Carol take over ownership? In order to do this, Alice advertises Bob's preimage. Carol can sign Bob's preimage and perform the same upload/pay invoice that Bob did.

Now that may be a lot to unpack, so you may want to go through it a few time. And don't worry, if you don't [grok](https://www.merriam-webster.com/dictionary/grok) the concept completely you'll still be able to build the application. After a few goes at making Bob and Carol the leaders it will hopefully become more intuitive.
