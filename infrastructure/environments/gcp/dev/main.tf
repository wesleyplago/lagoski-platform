provider "google" {
  project        = var.project_id
  region         = var.region
  default_labels = local.labels
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "southamerica-east1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "state_bucket" {
  type = string
}

locals {
  labels = {
    project     = "lagoski"
    service     = "platform"
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "platform" {
  source = "../../../modules/gcp-platform"

  project_id          = var.project_id
  region              = var.region
  prefix              = "lagoski-${var.environment}"
  topics              = ["catalog.events", "ordering.events", "inventory.events", "payment.events", "fulfillment.events"]
  github_owner        = "wesleyplago"
  deploy_repositories = ["lagoski-platform", "lagoski-catalog", "lagoski-ordering", "lagoski-inventory", "lagoski-payment", "lagoski-fulfillment", "lagoski-notification", "lagoski-bff"]
  state_bucket        = var.state_bucket
  labels              = local.labels
}

output "service_platform" {
  value = module.platform.service_platform
}

output "project_number" {
  value = module.platform.project_number
}

output "artifact_registry" {
  value = module.platform.artifact_registry
}

output "workload_identity_provider" {
  value = module.platform.workload_identity_provider
}

output "deploy_service_account" {
  value = module.platform.deploy_service_account
}
