# Cryptographic Primitives

This application uses hashes and digital signatures. We'll briefly walk through a few things used, but you are encouraged to fully understand both of these concepts.

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
