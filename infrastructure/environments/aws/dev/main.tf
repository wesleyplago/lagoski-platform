provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "certificate_arn" {
  type    = string
  default = null
}

locals {
  tags = {
    project     = "lagoski"
    service     = "platform"
    environment = var.environment
    repository  = "wesleyplago/lagoski-platform"
    managed_by  = "terraform"
  }
}

module "platform" {
  source = "../../../modules/aws-platform"

  prefix              = "lagoski-${var.environment}"
  availability_zones  = ["${var.region}a", "${var.region}b"]
  topics              = ["catalog.events", "ordering.events", "inventory.events", "payment.events", "fulfillment.events"]
  certificate_arn     = var.certificate_arn
  github_owner        = "wesleyplago"
  github_environment  = "aws-${var.environment}"
  deploy_repositories = ["lagoski-platform", "lagoski-catalog", "lagoski-ordering", "lagoski-inventory", "lagoski-payment", "lagoski-fulfillment", "lagoski-notification", "lagoski-bff"]
  tags                = local.tags
}

output "service_platform" {
  value = module.platform.service_platform
}

output "public_url" {
  value = module.platform.public_url
}

output "deploy_role_arns" {
  value = module.platform.deploy_role_arns
}
