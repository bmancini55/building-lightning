# Conclusion

We now have a basic application that uses invoices to chain ownership. Astute readers may have already recognized a few issues with this approach already.

What if Bob and Carol both have invoices for to take leadership in a chain? A standard invoice is automatically resolved when payment is received. How could you modify the application to allow conditional payment resolution?

This scheme could be extended to perform digital transfer. How might this scheme be modified to so that the current leader becomes part of the payment for the new transaction?

Lastly, the current scheme requires the server to publish its signature for an owner to reconstruct the proof. Is there anyway to modify the scheme so that the preimage contains all the information needed for the leader to construct a proof but still be a proof of payment (meaning it is not guessable by the payer unless they pay)?
