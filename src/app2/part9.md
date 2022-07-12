# Further Exploration

I hope you have enjoyed building this application and learned a bit more about building Lightning Applications with invoices. There is still a lot to explore and this application is ripe for extending in interesting ways. Astute readers may have already recognized a few issues with this approach already. A few thoughts to leave you with:

What if Bob and Carol both have invoices for to take leadership in a chain? A standard invoice is automatically resolved when payment is received. How could you modify the application to allow conditional payment resolution?

This scheme could be extended to perform digital transfer. How might this scheme be modified to so that the current leader becomes part of the payment for the new transaction?

Lastly, the current scheme requires the server to publish its signature for an owner to reconstruct the proof. Is there anyway to modify the scheme so that the preimage contains all the information needed for the leader to construct a proof but still be a proof of payment (meaning it is not guessable by the payer unless they pay)?
