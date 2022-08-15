# Further Exploration

I hope you have enjoyed building this application and learned a bit more about building Lightning Applications with invoices. This application is ripe for extending in interesting ways. Astute readers may have already recognized a few issues with this approach already. A few thoughts to leave you with:

- What if Bob and Carol both pay invoices to take leadership in a chain? A standard invoice is automatically resolved when payment is received. How could you modify the application to allow conditional payment resolution?

- This scheme could be extended to perform digital transfer. How might this scheme be modified to so that the current leader is required to participate in the transfer of leadership?

- The current scheme requires the server to publish its signature of the `linkId` for an owner to reconstruct the proof. Is there anyway to modify the scheme so that the preimage contains all the information needed for the owner to reconstruct a proof of ownership with only the preimage?
