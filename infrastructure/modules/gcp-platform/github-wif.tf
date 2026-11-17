# Deploy sem chaves: Workload Identity Federation com o OIDC do GitHub.

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "${var.prefix}-github"
  display_name              = "GitHub Actions (Lagoski)"
  depends_on                = [google_project_service.this]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.owner"      = "assertion.repository_owner"
  }
  attribute_condition = "assertion.repository_owner == \"${var.github_owner}\""
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "deploy" {
  project      = var.project_id
  account_id   = "${var.prefix}-deploy"
  display_name = "Lagoski deploy (GitHub Actions)"
}

resource "google_service_account_iam_member" "deploy_wif" {
  for_each           = toset(var.deploy_repositories)
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_owner}/${each.value}"
}

resource "google_project_iam_member" "deploy" {
  for_each = toset([
    "roles/run.admin",
    "roles/pubsub.admin",
    "roles/cloudsql.admin",
    "roles/secretmanager.admin",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.deploy.email}"
}

resource "google_storage_bucket_iam_member" "deploy_state" {
  bucket = var.state_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.deploy.email}"
}
