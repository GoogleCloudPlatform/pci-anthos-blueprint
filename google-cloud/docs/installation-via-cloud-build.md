# Installing via Cloud Build

* Make sure the steps in [Getting Started](getting-started.md) are complete before continuing here.

## Create the Cloud Build Trigger

* The repository includes a function that generates the required trigger. These steps illustrate what is needed to run it.
* Connect your repository so that it can be used as a Cloud Build trigger:
  * Navigate to [Cloud Build Triggers](https://console.cloud.google.com/cloud-build/triggers), ensuring that the admin project is selected.
  * Choose Connect repository > GitHub (Cloud Build GitHub App) > Authenticate > Select repository.
  * Don't create a push trigger, that is handled by the scripted function in the next step.
  * Either from a cloud shell, or from a command line, create the Cloud Build trigger via the `generate_cloud_build` function in [scripts/main.sh](../scripts/main.sh). This uses the [gcloud beta builds triggers create github](https://cloud.google.com/sdk/gcloud/reference/beta/builds/triggers/create/github) command:

```
source vars.sh
source scripts/main.sh
generate_cloud_build
```

* Add IAM permissions to the cloud build service account:
  * Using the console, retrieve the Cloud Build service account email address from the [Cloud Build settings](https://console.cloud.google.com/cloud-build/settings/service-account)
  * In IAM, add these permissions:
      * Organization Admin and Service Account Admin on the organization
      * On the folder to be used (`_TF_VAR_FOLDER_ID`): Compute Admin, Kubernetes Engine Admin, Service Account Key Admin, Owner, Project Creator
      * Sufficient privileges to access the `TF_ADMIN_BUCKET` created earlier.
* In a branch that matches `CLOUD_BUILD_BRANCH_PATTERN` as defined in `vars.sh`, commit and push to your repository. This will cause a build to start. Watch its progress in the [Build history](https://console.cloud.google.com/cloud-build/builds) section of the console. Note that the cluster creation step can take ~30 minutes to complete.
* After a successful first run, complete the steps in [DNS](dns.md) to set up DNS as needed.
* Check the Google-managed SSL certificate status as described in [Checking the Google-managed SSL certificate status](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#certificate-resource-status). This should complete automatically, and may take some time. Make sure to select the certificates page of the application project, `TF_VAR_project_app1` and not the admin project.
* Once the certificate is "Status: Active", the deployed application should be accessible at `https://DOMAIN_NAME` as set in `vars.sh`.
