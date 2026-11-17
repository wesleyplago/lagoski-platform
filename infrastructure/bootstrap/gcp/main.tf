# Bucket do state de todos os repositórios Lagoski no GCP. Aplicado uma vez, com state local.
terraform {
  required_version = ">= 1.10"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.14"
    }
  }
}

provider "google" {
  project = var.project_id
}

variable "project_id" {
  type = string
}

variable "location" {
  type    = string
  default = "SOUTHAMERICA-EAST1"
}

resource "google_storage_bucket" "state" {
  name                        = "lagoski-tfstate-${var.project_id}"
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning {
    enabled = true
  }
  labels = { project = "lagoski", managed_by = "terraform" }
}

output "state_bucket" {
  value = google_storage_bucket.state.name
}
