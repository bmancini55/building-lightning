# Creating an LND REST Client

## Connecting

Because LND uses a self-signed certificate we need to provide this to the TLS connection when we make a REST request. Many examples will have you specify the `rejectUnauthorized=false` option to get around self-signed certificates. This introduces a risk of man-in-the-middle attacks. Instead Node.js provides a mechanism that allows us to specify a verification certificate.

Node.js enables us to supply a list of additional Certificate Authorities via the [`NODE_EXTRA_CA_CERTS`](https://nodejs.org/api/cli.html#cli_node_extra_ca_certs_file) command line option. With this you would specify the path to the certificate before you run your node process:

```bash
NODE_EXTRA_CA_CERTS="/home/lndev/.polar/networks/2/volumes/lnd/alice/tls.cert" ts-node test.ts
```

The limitation of this method is that these are only read at process startup. So we would have to know all of the machines we want to connect to. Instead we can read the PEM file and supply a `Buffer` as the `ca` option in `https.request`.
