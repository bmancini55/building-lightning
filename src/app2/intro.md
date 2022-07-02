# Building on Lightning: Working with Invoices

This section is going to focus on building an application to accept payments using the Lightning Network.

Payments in Bitcoin are fairly straightforward because they use a "account-like" system that is familiar to most people. In Bitcoin, the recipient of a payment provides an address to the sender. The address can be provided out-of-band (through a website, email, or text message) to anyone. The payment sender can then initiates a payment to the address at any time and for any amount. They can even make multiple payments to the same address.

The Lightning Network handles payments in a different manner. The primary mechanism for sending payments uses invoices also known as payment requests. An invoice acts like a payment instructions for a conditional payment. As such invoices are typically one time use and are intended for a specific purpose and amount. Functionally, this means that an invoices tells the sender: who, how much, and within what time frame to send a payment. The invoice is also digitally signed by the recipient. The signature ensures that an invoice can't be forged (Carol can't create an invoice for Alice). The last and possibly most important piece is that the invoice includes the hash of information that only the recipient knows (under normal circumstances at least).

Let's consider an example. Say Alice runs a web store and Bob wants to buy a t-shirt. He adds the shirt to his cart and goes to check out. At this point, Alice creates an invoice for Bob. This invoice includes the cost of the shirt, a timeout that Bob needs to complete the transaction, some secret value hidden in a hash, and Alice's signature for the invoice.

When Bob pays Alice she reveals the preimage for the secret and this acts as a proof of payment. Alice would only ever reveal the preimage to Bob if he made payment. Bob can only have the preimage for the invoice if he makes the payment. Bob has a signed invoice from Alice stating the conditions of the transaction and has proof that he paid her in the form of the preimage for the hash in the invoice.

So why all this complexity? It enables one of the primary purposes of the of the Lightning Network which is to enable trustless payments through the network. This scheme allows payments to flow through the network even if Bob and Alice aren't directly connected. If you're unsure on how this works or want a refresher, I recommend reading this [article](https://medium.com/@peter_r/visualizing-htlcs-and-the-lightning-networks-dirty-little-secret-cb9b5773a0).

For this application we'll be using the idea of generating a secret based on some information that only the server knows. We can then reveal this information publicly and publicly prove that a payment was made.

For a more thorough walk through of invoices, check out Chapter 15 of _Mastering the Lightning Network_ by Antonopoulos et al.

# Goal of the Application

We're going to create a self-contained application that relies on the invoice database in our Lightning Network node. We're going to use the Lightning Network and invoices to create a virtual game of "king of the hill". To play the game, someone becomes the leader by paying an invoice. Someone else can be the new leader by paying an invoice for more than the last leader. The neat thing is that we'll do this in a way that any leader along the way can cryptographically prove they paid to be the leader. In a sense, this application will act as a simple provenance chain for a "digital right" using invoices.

We'll get into the details of the application as we go, but we'll show what the game looks like from the perspective of Bob, who wants to become the first leader.

![Initial App](/images/ch2_app_01.png)

If Bob wants to become the leader he digitally signs the message `0000000000000000000000000000000000000000000000000000000000000001` provided by the application using his Lightning Network node.
![Bob Signs](/images/ch2_app_02.png)

Note: In Polar we can open a terminal to do this by right-clicking on the node and selecting "Launch Terminal". With c-lightning, you can use the command `signmessage`. It will return a signature in hex and zbase32 formats. To simplify our application we'll use the zbase32 format since LND only interprets signatures in this format.

Now that Bob has his signature, he provides the signature to the application in the user interface. The server (run by Alice) creates an invoice using Alice's Lightning Network node. This invoice is specific to Bob. Alice's server returns the invoice to Bob via the user interface.

![Bob Invoice](/images/ch2_app_03.png)

At this point, Bob can pay the invoice.

![Bob Pays](/images/ch2_app_04.png)

Once Bob has paid the invoice he is now the new leader of the game!

![Bob is the Leader](/images/ch2_app_05.png)

If Carol wants to become the new leader, she can sign the message `9c769de3f07d527b7787969d8f10733d86c08b253d32c3adc7067f22902f6f38` using her Lightning Network node.

![Carol Signs](/images/ch2_app_06.png)

Note: In Polar, we once again can use the "Launch Terminal" option. With LND, you can also use the CLI command `signmessage`. This will only return a zbase32 format signature, which is the format our application requires.

Carol provides this signature via the user interface and the Alice's server generates an invoice specifically for Carol to become the leader of the game at point `9c769de3f07d527b7787969d8f10733d86c08b253d32c3adc7067f22902f6f38`.

![Carol Invoice](/images/ch2_app_07.png)

When Carol pays the invoice she will become the new leader!

![Carol Leader](/images/ch2_app_08.png)
