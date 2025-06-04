resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  project       = var.project_id
  repository_id = "${var.environment}-docker-repo"
  description   = "Docker repository for ${var.environment} environment"
  format        = "DOCKER"

  docker_config {
    immutable_tags = false
  }
}

resource "google_artifact_registry_repository" "helm_repo" {
  location      = var.region
  project       = var.project_id
  repository_id = "${var.environment}-helm-repo"
  description   = "Helm repository for ${var.environment} environment"
  format        = "DOCKER"
}
