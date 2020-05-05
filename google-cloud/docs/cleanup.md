# Cleaning Up

Follow these steps to delete the resources created and managed in this project.

# Run the Cloud Build cleanup pipeline

* A Cloud Build pipeline named "terraform-destroy" is created in the admin project when the `/cloud-build` terraform was run. It is disabled by default. When enabled, it will be triggered by a tag matching the regex as defined by `cloud_build_destroy_tag_regex_pattern`, which is set to `destroy-*`. Run the pipeline by enabling it in the console and pushing a matching tag. eg.

```sh
TAG="destroy-1"
git tag $TAG ; git push origin $TAG
```

Once the app and network projects are deleted, you can continue to the next step.

## Run `terraform destroy` in the cloud-build directory

* This will delete all resources managed by terraform in the cloud-build directory

```sh
cd cloud-build
terraform destroy [-force]
```

## Run `terraform destroy` in the admin directory

* This will delete all resources managed by terraform in the admin directory

```sh
cd admin
terraform destroy [-force]
```
