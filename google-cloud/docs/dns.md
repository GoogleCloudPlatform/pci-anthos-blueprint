# DNS Configuration

The install includes delegating a subdomain to a Cloud DNS hosted zone. If using the domain `yourdomain.com`, `test.yourdomain.com` can be used for the DNS hosted zone, and the demo application will be hosted at `https://store.test.yourdomain.com` by default.


* Included in the terraform configuration is a Cloud DNS zone and record for the frontend ([dns.tf](../infrastructure/dns.tf)). Included in the terraform output will be the new zone's nameservers. For example:

```
$ terraform apply terraform.out
...

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

frontend_zone_dns_name = a.example.com
in_scope_ingress = 1.2.3.4
nameservers = [
  "ns-cloud-e1.googledomains.com.",
  "ns-cloud-e2.googledomains.com.",
  "ns-cloud-e3.googledomains.com.",
  "ns-cloud-e4.googledomains.com.",
]
```

Using the appropriate DNS management method for your domain, update or create the NS record to match `a.example.com` as outputted by terraform. When correctly configured and propagated, testing via `dig` should match terraform's output. Using the above example:

```sh
$ dig +noall +answer  NS a.example.com

a.example.com. 3600	IN	NS	ns-cloud-e4.googledomains.com.
a.example.com. 3600	IN	NS	ns-cloud-e2.googledomains.com.
a.example.com. 3600	IN	NS	ns-cloud-e3.googledomains.com.
a.example.com. 3600	IN	NS	ns-cloud-e1.googledomains.com.
```
