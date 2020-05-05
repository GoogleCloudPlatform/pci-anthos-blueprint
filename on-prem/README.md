# Anthos Blueprint: PCI compliance using Anthos on-prem
This repo contains a sample app and configuration that provides a baseline for addressing 
Payment Card Industry Data Security Standard (PCI DSS) compliance requirements using [Anthos GKE on-prem](https://cloud.google.com/anthos/gke/docs/on-prem/overview).

As a companion to this repo and instructions you are strongly advised to read:
* the associated [PCI for Anthos on-prem](https://cloud.google.com/architecture/blueprints/gke--on-prem-pci-dss-blueprint) 
user guide
* the GKE on-prem [security overview](https://cloud.google.com/anthos/gke/docs/on-prem/concepts/security)
* the GKE on-prem [cluster hardening guide](https://cloud.google.com/anthos/gke/docs/on-prem/how-to/hardening-your-cluster)


## Caveats
This blueprint is provided with the following caveats and limitations:
* This blueprint is for demonstration purposes only
* Implementing the blueprint alone does **not** provide compliance with all PCI DSS requirements
* Securing Anthos GKE on-prem is a [shared responsibiltiy](http://cloud/anthos/docs/concepts/gke-shared-responsibility). 
For example, you are responsible for:
  * Appropriately segmenting the underlying vSphere networks
  * Configuring appropriate firewall rules
  * Operating, maintaining, and patching infrastructure, including networks, servers and storage 

## Architecture
![](./pci-gke-onprem-arch.png)

## Summary
In this blueprint you:
 * Use the [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo) demo ecommerce app
 * Split the Online Boutique microservices over two distinct GKE on-prem clusters
   * Microservices that handle cardholder data are in scope for PCI compliance and are deployed 
   to an `in-scope` GKE on-prem cluster
   * Other microservices are not in scope for PCI compliance and are deployed to an `out-of-scope` 
   GKE on-prem cluster. 
 * Place the in-scope and out-of-scope GKE clusters on separate underlying networks
 * Use [Anthos Config Management](https://cloud.google.com/anthos/config-management) to apply 
 and maintain appropriate cluster configuration, synced from a Git repo
 * Use [Anthos Service Mesh](https://cloud.google.com/anthos/service-mesh) to secure and constrain 
 traffic within and across the GKE on-prem clusters

## Supported versions
This installation has been tested and verified against the following versions:
* GKE on-prem: 1.4.0-gke.13, and Anthos Service Mesh: 1.6.5-asm.1
* GKE on-prem: 1.4.3-gke.3, and Anthos Service Mesh: 1.6.5-asm.1

## Security controls
This section describes the security controls used by the blueprint.

### Network controls
Configuring the underlying vSphere networks is outside the scope of the blueprint. See the GKE on-prem 
[networking overview](https://cloud.google.com/anthos/gke/docs/on-prem/concepts/networking)
and the related [vSphere network requirements](https://cloud.google.com/anthos/gke/docs/on-prem/how-to/network-basic) for more details.

You are responsible for:
* Segmenting the vSphere networks such that resources that are in-scope for PCI compliance are on separate networks 
than those that are out-of-scope.
* Placing the in-scope resources on private, internal networks. Access to the internet must be through an appropriately
configured NAT device.
* Configuring firewall rules to allow only known traffic to and from the network(s) containing in-scope resources.
* Restricting access to the admin workstation to only authorized users.

### Network policies
Kubernetes [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) 
enforce Layer 4 network traffic flows by using Pod-level firewall rules. Here, you create network policies to 
control traffic to, from and within the `store-in-scope` namespace. The policies:
* by default, deny all ingress and egress traffic
* allow egress traffic only to certain cluster-internal resources like kube-dns and istio-system
* allow egress traffic to the out-of-scope cluster, via the out-of-scope LoadBalancer VIP
* allow ingress and egress to and from specific services within the namespace. For example, only
allow ingress to `paymentservice` pods from `checkoutservice` pods.

### Anthos Service Mesh
Anthos Service Mesh helps you monitor and manage an [Istio](https://istio.io/docs/concepts/what-is-istio/) -based service mesh. 
A service mesh is an infrastructure layer that enables managed, observable, and secure communication across your services.
In this blueprint, you deploy a service mesh with the following characteristics:
* Multi-primary. Each GKE cluster operates its own mesh, and has its own Istio control plane.
* Multi-network. The GKE clusters are in separate vSphere networks to enforce strong isolation between the in-scope
and out-of-scope resources.
* Multi-cluster. The meshes are configured to exchange endpoint information, so services in the in-scope cluster can
communicate with services in the out-of-scope cluster
* The store-in-scope and store-out-of-scope namespaces are enabled for Istio proxy injection. Pods in these namespaces
receive Istio sidecar proxy containers.

You use the below controls provided by Anthos Service Mesh and Istio. Generally speaking, these controls restrict
traffic at the application layer. These controls are on top of the network layer restrictions provided by Network
Policies. Applying controls at both layers helps you adopt a defense-in-depth strategy.
* For the in-scope cluster, you set the mesh outboundTrafficPolicy to `REGISTRY_ONLY` such that the Istio proxy blocks
access to external resources by default. If an in-scope microservice requires access to an external resource, that
access must be explicitly configured. 
* Istio [AuthorizationPolicies](https://istio.io/latest/docs/reference/config/security/authorization-policy/) 
to control which microservices can call each other. For example:
  * allow requests to services in the `store-in-scope` namespace only from other services within the
  `store-in-scope` namespace (except Frontend, which allows external requests).
  * allow requests only from authenticated services
* Istio [AuthenticationPolicies](https://istio.io/latest/docs/tasks/security/authentication/authn-policy/) to:
  * use STRICT mTLS for all service-to-service communication

### Anthos Config Management
You use [Anthos Config Management](https://cloud.google.com/anthos/config-management) to manage 
the configuration of your GKE on-prem clusters. Config Management keeps your clusters in sync 
with configs defined in a Git repo. In this blueprint, you use Config Sync to create and manage cluster objects
including:
* Namespaces, such as the store-in-scope and store-out-of-scope namespaces that contain the app microservices
* Network policies, as described above
* Istio Authorization policies, as described above
* Istio PeerAuthentication rules, as described above

### Anthos Policy Controller
You also use [Anthos Policy Controller](https://cloud.google.com/anthos-config-management/docs/concepts/policy-controller),
a dynamic admission controller for Kubernetes that enforces CustomResourceDefinition-based (CRD-based) policies that
are executed by the Open Policy Agent (OPA). In this blueprint, you enforce:
* a policy which ensures that the PeerAuthentication rule for strict mutual TLS is not changed.


## Prequisites
To install this blueprint you need:

 * A Google Cloud project with billing enabled and an Anthos subscription. See the [Setting up Anthos](https://cloud.google.com/anthos/docs/setup/overview) docs.
 * An appropriately configured VMware vSphere environment running in your data center. See the [vSphere requirements](https://cloud.google.com/anthos/gke/docs/on-prem/how-to/vsphere-requirements-basic) docs.
 * A GKE on-prem [installation](https://cloud.google.com/anthos/gke/docs/on-prem/how-to/install-overview-basic) including
   * An admin workstation. 
   * One admin cluster
   * Two user clusters. 
     * The basic GKE on-prem installation creates one user cluster. See the [creating a user cluster](https://cloud.google.com/anthos/gke/docs/on-prem/how-to/create-user-cluster)
     docs for details on how to add another user cluster.
   * Load balancers configured with virtual IP addresses (VIP)
     * For this blueprint, you require an additonal VIP per user cluster
     * These VIPs are used as the entry point for the Online Boutique services via an Istio IngressGateway 

## Installation
### Basics
1. `ssh` into the admin workstation that you used to create your GKE on-prem clusters

1. Clone this repo.   
`git clone https://github.com/GoogleCloudPlatform/pci-anthos-blueprint.git`

1. Change into the on-prem/scripts directory. Note that the repo contains several blueprints;
here you are concerned only with the on-prem directory  
`cd pci-anthos-blueprint/on-prem/scripts`

### Create a new Git repo
You use [Anthos Config Management](https://cloud.google.com/anthos/config-management) to manage 
the configuration of your GKE on-prem clusters. Config Management keeps your clusters in sync 
with configs defined in a Git repo. In this section you create a new Git repo to store configs with settings
specific to your environment.

1. Update the network policies to reference the LoadBalancer ingress VIP for the out-of-scope cluster. The network policy
restricts egress from the in-scope cluster, but allows egress to the out-of-scope VIP. In this way the in-scope
microservies can call the out-of-scope microservces. Supply the ingress VIP for your out-of-scope cluster:    
`./updateNetworkPolicy.sh <OUT_OF_SCOPE_INGRESS_VIP>`

1. Create a new local Git repo. For example:  
`git init ~/anthos-onprem-pci-acm`
  
1. Copy the contents of demo/config-management directory to your new local repo. For example:  
`cp -r ../demo ~/anthos-onprem-pci-acm/`

1. Commit the changes, and push the repo to a remote location such that Config Management can 
read the repo e.g. GitHub

### Setup
1. Edit the `vars.sh` file, supplying values such as:
   1. paths to the kubeconfig files for each user cluster
   1. LoadBalancer VIPs to be used for the Istio IngressGateways 

1. Update `vars.sh` with the details of your remote Git repo created in the previous step.
    ```
    # some accessible repo that you own
    export ACM_SYNCREPO="https://github.com/someuser/anthos-onprem-pci-acm"
    # ACM will sync from this branch
    export ACM_SYNCBRANCH="master"
    # assumes the repo is publicly accessible
    export ACM_SECRETTYPE="none"
    # the directory within the repo that contains the configs.
    export ACM_POLICYDIR_ROOT="demo/config-management"
    ``` 

    **NOTE:** For simplicity, this blueprint assumes that your new repo is accessible
    such that the Config Management Operator can read the repo without credentials.
    If this is not the case, you will need to follow the instructions at:
    [Granting the Operator read-only access to Git](https://cloud.google.com/anthos-config-management/docs/how-to/installing#git-creds-secret)

1. Perform initial setup; dowload required softwares  
`./setup.sh`


### Install Anthos Service Mesh
You install Anthos Service Mesh into both user clusters. Each cluster operates its own Istio 
control plane. The clusters share trust and are configured to exchange endpoint information, 
allowing Istio to route traffic across clusters using mutual TLS. For simplicity, the default Istio
certificates are used; you should not use these in production.

**Steps:**
1. Install and setup Anthos Service Mesh  
`./asm.sh`

### Install Anthos Config Management
You use Anthos Config Management to automatically apply configuration to your clusters including
Namespaces, Istio traffic management rules, authorization policies, and more. The configs are synced
from the repo you created earlier.

**Steps:**
1. Install and setup Anthos Config Management in both user clusters.   
`./acm.sh` 

### Deploy the Online Boutique app
Deploy the Online Boutique microservices into the user clusters; this creates Kubernetes Deployments
and associated Services in the clusters. Microservices that handle cardhodler data are deployed
into the `in-scope` cluster. Microservices that do not handle cardholder data are
deployed into the `out-of-scope` cluster. Separating services that are in-scope and out-of-scope 
for PCI compliance is a best practice.

Note that out-of-scope Services are also created in the in-scope cluster. These are "empty" Services; 
there are no Deployments or Pods associated with these out-of-scope Services in the in-scope cluster. 
These "empty" Services exist to allow Kubernetes to successfully resolve out-of-scope Service names
in the in-scope cluster. However, Istio correctly routes these calls to the real Service in the
out-of-scope cluster. 

**Steps:**
1. Deploy the microservices  
`./store.sh`

### Verify the application
For simplicity, this installation:
 * Uses a self-signed certificate. You will need to accept the warning from your browser to proceed
 to the app home page
 * Does not configure DNS. You connect to the app using an IP address.
 
**Steps:**
1. Open a browser to the address of the `IN_SCOPE_ISTIO_INGRESS_IP` value; accept self-signed cert warnings  
`https://IN_SCOPE_ISTIO_INGRESS_IP`

1. View some products, add to Cart and complete Checkout to verify application is functioning correctly. 
