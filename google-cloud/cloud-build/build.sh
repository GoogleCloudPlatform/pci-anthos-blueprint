#!/bin/bash

echo "Has the repository connection been created?"
echo "Has the config-management-deploy-key secret been added?"

source ../vars.sh
envsubst < backend.tf.tmpl > backend.tf
envsubst < terraform.tfvars.tmpl > terraform.tfvars
terraform init
terraform plan -out terraform.out
