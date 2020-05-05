#!/bin/bash
source ../vars.sh
envsubst < backend.tf.tmpl > backend.tf
envsubst < terraform.tfvars.tmpl > terraform.tfvars
terraform init
terraform plan -out terraform.out
