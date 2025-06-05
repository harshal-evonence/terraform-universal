# Network outputs
output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "regional_subnet_id" {
  description = "Regional Subnet ID"
  value       = google_compute_subnetwork.regional_subnet.id
}


# GKE outputs
output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "gke_service_account_email" {
  description = "GKE service account email"
  value       = google_service_account.gke_service_account.email
}

# Database outputs
output "mysql_connection_name" {
  description = "MySQL connection name"
  value       = module.safer-mysql-db.instance_connection_name
  sensitive   = true
}

output "postgresql_connection_name" {
  description = "PostgreSQL connection name"
  value       = module.pg-db.instance_connection_name
  sensitive   = true
}

# Redis outputs

output "redis_cluster_endpoint" {
  description = "Redis cluster discovery endpoint"
  value       = google_redis_cluster.redis_cluster.discovery_endpoints[0].address
  sensitive   = true
}

# Artifact registry outputs

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}

# VM outputs

output "confidential_vm_name" {
  description = "Confidential VM instance name"
  value       = google_compute_instance.confidential_vm.name
}