data "google_project" "this" {
  project_id = var.project_id
}

locals {
  apis = [
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "servicenetworking.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ]
  pubsub_service_agent = "service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_project_service" "this" {
  for_each           = toset(local.apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# ------------------------------------------------------------------ rede

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.prefix
  auto_create_subnetworks = false
  depends_on              = [google_project_service.this]
}

resource "google_compute_subnetwork" "this" {
  project                  = var.project_id
  name                     = "${var.prefix}-${var.region}"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

# Acesso privado ao Cloud SQL (sem IP público).
resource "google_compute_global_address" "private_services" {
  project       = var.project_id
  name          = "${var.prefix}-private-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.this.id
}

resource "google_service_networking_connection" "this" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}

# -------------------------------------------------------------- dados

# Uma instância (custo); cada serviço cria o próprio database e usuário.
resource "google_sql_database_instance" "this" {
  project             = var.project_id
  name                = var.prefix
  region              = var.region
  database_version    = "POSTGRES_16"
  deletion_protection = false

  settings {
    tier              = var.db_tier
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"
    disk_size         = 10
    user_labels       = var.labels

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.this.id
    }

    backup_configuration {
      enabled = false
    }
  }

  depends_on = [google_service_networking_connection.this]
}

# ---------------------------------------------------------- mensageria

resource "google_pubsub_topic" "this" {
  for_each                   = toset(var.topics)
  project                    = var.project_id
  name                       = "${var.prefix}-${replace(each.value, ".", "-")}"
  message_retention_duration = "604800s" # 7 dias: permite seek/replay
  labels                     = var.labels
  depends_on                 = [google_project_service.this]
}

# ------------------------------------------------------------ imagens

resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.region
  repository_id = "lagoski"
  format        = "DOCKER"
  labels        = var.labels

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 20
    }
  }

  depends_on = [google_project_service.this]
}

# Identidade do BFF criada aqui: os serviços internos concedem run.invoker a ela.
resource "google_service_account" "bff" {
  project      = var.project_id
  account_id   = "${var.prefix}-bff"
  display_name = "Lagoski BFF (runtime)"
}
