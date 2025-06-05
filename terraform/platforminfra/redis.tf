# Service Connection Policy for Redis Cluster
resource "google_network_connectivity_service_connection_policy" "redis_service_policy" {
  name          = "redis-service-policy"
  project       = var.project_id
  location      = var.region
  service_class = "gcp-memorystore-redis"
  description   = "Service connection policy for Redis cluster in ${var.environment} environment"
  network       = google_compute_network.vpc.id
  psc_config {
    subnetworks = [google_compute_subnetwork.regional_subnet.id]
  }
}

# Redis Cluster
resource "google_redis_cluster" "redis_cluster" {
  name           = "test-redis-cluster"
  project        = var.project_id
  region         = var.region
  shard_count    = 1
  replica_count  = 1
  node_type      = "REDIS_SHARED_CORE_NANO"
  transit_encryption_mode = "TRANSIT_ENCRYPTION_MODE_DISABLED"
  authorization_mode = "AUTH_MODE_DISABLED"
  redis_configs = {
    maxmemory-policy = "volatile-ttl"
  }
  deletion_protection_enabled = true

  psc_configs {
    network = google_compute_network.vpc.id
  }

  zone_distribution_config {
    mode = "MULTI_ZONE"
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "MONDAY"
      start_time {
        hours   = 1
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  depends_on = [
    google_compute_network.vpc,
    google_compute_subnetwork.regional_subnet,
    module.enable_apis,
    google_network_connectivity_service_connection_policy.redis_service_policy
  ]
}