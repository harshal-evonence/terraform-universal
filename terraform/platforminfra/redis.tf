resource "google_redis_cluster" "redis_cluster" {
  name          = "test-redis-cluster"
  region        = var.region
  project       = var.project_id
  shard_count   = 1
  replica_count = 1
  node_type     = "REDIS_STANDARD_SMALL"

  psc_configs {
    network = google_compute_network.vpc.id
  }

  depends_on = [
    google_compute_network.vpc,
    module.enable_apis
  ]
}
