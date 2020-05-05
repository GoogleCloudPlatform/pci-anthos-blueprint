variable "project_prefix" {
  description = "Segment to prefix all project names with."
  default     = ""
}
variable "organization_id" {}
variable "region" {}
variable "src_path" {}
variable "asm_path" {}
variable "in_scope_cluster" {}
variable "out_of_scope_cluster" {}
variable "terraform_base_bucket_name" {
  default = ""
}
variable "terraform_base_bucket_prefix" {
  default = ""
}
variable "billing_account" {
  description = "The ID of the associated billing account"
}
variable "cloud_build_github_owner" {
  default = ""
}
variable "cloud_build_repository_name" {
  default = ""
}
variable "cloud_build_push_branch_pattern" {
  default = ""
}
variable "frontend_hostname" {
  default = ""
}
variable "frontend_zone_dns_name" {
  default = ""
}
variable "acm_syncrepo" {
  default = ""
}
variable "acm_syncbranch" {
  default = ""
}
locals {
  cloudbuild_yaml_filename = "google-cloud/cloudbuild.yaml"
  cloudbuild_yaml_destroy_filename = "google-cloud/destroy.yaml"
  cloud_build_destroy_tag_regex_pattern = "destroy-*"
  cloud_build_destroy_disabled = true
}

