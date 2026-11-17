# Contrato com os repositórios de serviço: o tipo deste objeto é o da variável
# `platform` do módulo gcp-service.
output "service_platform" {
  value = {
    network_id                = google_compute_network.this.id
    subnet_id                 = google_compute_subnetwork.this.id
    sql_instance_name         = google_sql_database_instance.this.name
    sql_private_ip            = google_sql_database_instance.this.private_ip_address
    topic_ids                 = { for name, t in google_pubsub_topic.this : name => t.id }
    pubsub_service_agent      = local.pubsub_service_agent
    bff_service_account_email = google_service_account.bff.email
  }
}

output "project_number" {
  description = "Usado para montar as URLs determinísticas do Cloud Run."
  value       = data.google_project.this.number
}

output "artifact_registry" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}"
}

output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "deploy_service_account" {
  value = google_service_account.deploy.email
}
