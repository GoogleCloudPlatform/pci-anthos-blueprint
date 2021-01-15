# Self-signed certificate for demonstration use

These are the steps used to create the self signed certificate, and its associated Kubernetes Secret. Note that the snakeoil secret
for `example.com` is included in `/app/mci/snakeoil-frontend-cert-secret.yaml`, and added to the cluster via `main.sh`, so no action 
needs to be taken. This doc is for documenting the steps taken. Production scenarios will need CA-signed certtificates.

Cert generation:

```sh
$ openssl req -new -newkey rsa:2048 -nodes -keyout snakeoil.key -out snakeoil.csr
```

Example output:

```sh
Generating a 2048 bit RSA private key
...........................+++
................................................................................................+++
writing new private key to 'snakeoil.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:
State or Province Name (full name) []:
Locality Name (eg, city) []:
Organization Name (eg, company) []:
Organizational Unit Name (eg, section) []:
Common Name (eg, fully qualified host name) []:example.com
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
```

* Generate the .pem file:

```sh
$ openssl x509 -req -sha256 -days 365 -in snakeoil.csr -signkey snakeoil.key -out snakeoil.pem
```

Example output:

```sh
Signature ok
subject=/CN=example.com
Getting Private key

```

* Finally, create the required kubernetes Secret. 

```sh
kubectl --context r3-1 -n istio-system create secret tls frontend-cert-secret --key  snakeoil.key --cert  snakeoil.pem
```