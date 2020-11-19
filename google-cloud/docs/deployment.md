# Deployment

## Overview

This repository contains code that creates an administrative project and two managed projects: a networking one to contain the VPC configuration, and an application project to contain the GKE clusters and their configurations. The networking and application projects are contained in an infrastructure folder, and everything is contained in a top-level folder for ease of management and cleanup.

The administrative ("admin") project contains a Cloud Build configuration, along with a GCS bucket to contain terraform state files. Cloud Builds are run in this project. The admin project and its dependencies are managed via terraform contained in the `/admin` directory.

After the admin project is created, the Cloud Build trigger can be created. It is managed by terraform configuration files in the `/cloud-build` directory.

The Cloud Build pipeline is triggered by pushes to its configured git repository. The pipeline, as defined in `cloudbuild.yaml` creates and manages the infrastructure resource folder, the network and application projects in that folder and the GKE clusters in the application project. Additionally, it configures the clusters to be managed via Anthos Config Management. The last step in the pipelineis the deployment of the demo application. 

Make sure you have read and understand the [DNS Configuration](dns.md) section in addition to the other [Requirements](../README.md#requirements) before continuing.

## Getting Started

### Copy this repository

To begin, clone or fork this repository. Note that the terraform code and these instructions require that both this repository and the Anthos Config Management repository be hosted via GitHub. However, this is not a requirement of any of the underlying technologies, and additional Git repository locations like Google Cloud Source Repository will likely be added in the future. 

### Configure Anthos Config Management prerequisites

The clusters are designed to use Anthos Config Management for their management configuration. Since Anthos Config Management uses a git repository to retrieve and synchronize cluster configuration, a repository for this purpose will need to be created. A copy of the Anthos Config Management files that are used are contained in this repository in the `demo/config-management` directory.

* Create a new repository to be used as the Anthos Config Management repository, and add the contents of `demo/config-management` to that repository. When complete, you should have two repositories: this one and the Anthos Config Management repository, whose top level directories are `in-scope` and `out-of-scope`.

## Create the admin project

* In your cloned working copy of this repository, copy `vars.sh.example` to `vars.sh`. This file will be used to contain all required environment variables.

### Create and populate custom variables

* The `vars.sh.example` file is commented with details describing how each variable is used. This is a list of the variables that will most likely need to be edited. It is a good idea to review all of the values in that file before continuing.

```
TERRAFORM_BASE_BUCKET_NAME="mybucket"
```
Choose (creating if needed) a Google Cloud storage bucket (in a pre-existing project) that your user has read/write access to. This will be used as the backend for terraform state of the `/admin` root module.

```
ORGANIZATION_ID
```
The Google Cloud Organization ID from the output of the command `gcloud organizations list`

```
BILLING_ACCOUNT
```
The billing account to be used for projects and their resources. This is `ACCOUNT_ID` from the output of the command `gcloud beta billing accounts list`

```
ADMIN_PARENT_FOLDER_ID
```
An optional folder ID to be used as parent for the admin folder. This is the ID from the output of the command `gcloud resource-manager folders list --organization=ORGANIZATION_ID`. If this is not specified the admin folder will be created at the organization root.

```
CLOUD_BUILD_GITHUB_OWNER
CLOUD_BUILD_REPOSITORY_NAME
```

The remote git repository owner and name to be used by the Cloud Build trigger. In `https://github.com/googlecloudplatform/cloud-builders`, the owner is `googlecloudplatform` and the name is `cloud-builders`.

```
FRONTEND_HOSTNAME
FRONTEND_ZONE_DNS_NAME
```
Set a DNS hostname ("www", "store", etc. ) and zone name ("mycompany.com", "dev.mycompany.com" ) to use. This will be used for DNS records as well as managed TLS certificates for the frontend load balancer. See [DNS](dns.md) for details.

```
ACM_SYNCREPO
ACM_SYNCBRANCH
```
The ssh form of the git repository address and branch used for Anthos Config Management.

## Run Terraform to create the Admin project

Once `vars.sh` is configured, the terraform code in `/admin` can now be applied. From the `admin` directory, run `build.sh`. That will populate templates as needed, and run `terraform init` and `terraform plan`. The output should be a terraform plan. You can now run `terraform apply`:

```
terraform apply terraform.out
```

After the above has completed successfully, continue to the next step.

## Create the Cloud Build trigger

In this section, the cloud build trigger will be created. The previous step created the admin project to contain it. Before continuing, there are two steps that need to be completeld.

### Create the repository connection to be used by the build pipeline

* Connect your repository (this one, not the the Anthos Config Management repository) so that it can be used as a Cloud Build trigger:
  * Navigate to [Cloud Build Triggers](https://console.cloud.google.com/cloud-build/triggers), ensuring that the admin project previously created is selected.
  * Choose Connect repository > GitHub (Cloud Build GitHub App) > Authenticate > Select repository.
  * When prompted, choose to skip, don't create a trigger- that is accomplished later via terraform.

### Add keys to allow automated access to the Anthos Config Management repository

* Generate an ssh key to be used as a deploy key that will be used to access the Anthos Config Management repository.
* Navigate to the settings section of the Anthos Config Management repository and add the public key as a deploy key. This will allow read access via the private key to the repository. This process is described in more detail [here](https://docs.github.com/en/free-pro-team@latest/developers/overview/managing-deploy-keys#setup-2).
* In in [Secret Manager](https://cloud.google.com/secret-manager/docs/creating-and-accessing-secrets) (ensuring that the Admin project has been selected), add the private key as a secret with the name `config-management-deploy-key`. 

* You are now ready to execute the terraform in the `/cloud-build` directory. There is a copy of `build.sh` in this directory as well. After running it, the output should be a terraform plan. As before, you can now apply the plan:

```
terraform apply terraform.out
```

This will create the Cloud Build pipeline. After the above has completed successfully, continue to the next step.

## Run the pipeline

In a branch that matches `CLOUD_BUILD_PUSH_BRANCH_PATTERN` as defined in `vars.sh`, commit and push to your (pci-anthos-blueprint) repository. This will cause a build to start. Watch its progress in the [build history](https://console.cloud.google.com/cloud-build/builds) section of the console. Note that the cluster creation step can take ~30 minutes to complete.
* After a successful first run of the terraform steps, the build's output will include the nameservers needed to complete the steps in [DNS](dns.md) to set up DNS.
* Check the Google-managed SSL certificate status as described in [Checking the Google-managed SSL certificate status](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#certificate-resource-status). This should complete automatically, and may take some time. In the Google Cloud console make sure to select the certificates page of the application project and not the admin project.
* Once the certificate is "Status: Active", the deployed application should be accessible at `https://${FRONTEND_HOSTNAME}/${FRONTEND_ZONE_DNS_NAME}` as defined in `vars.sh`.

