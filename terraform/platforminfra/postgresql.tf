#Cloud SQL for Postgres 14.0 with Public IP Address

module "pg-db" {
  depends_on = [google_compute_network.vpc]
  source     = "terraform-google-modules/sql-db/google//modules/postgresql"
  version    = "~> 23.0"

  name                 = var.pg_db_name
  random_instance_name = true
  project_id           = var.project_id

  deletion_protection = true

  database_version  = "POSTGRES_14"
  region            = var.region
  tier              = "db-custom-1-3840"
  availability_type = "REGIONAL" # Enables High Availability (HA) with failover replica

  # Optional flags (example: logging)
  database_flags = [
    {
      name  = "cloudsql.iam_authentication"
      value = "on" # Adjust as per requirements
    },
  ]

  # Enable private IP and disable public access
  ip_configuration = {
    authorized_networks = []                                   # No public IP, disable authorized networks for public access
    ipv4_enabled        = false                                # Disable public IP address
    private_network     = google_compute_network.vpc.self_link # Use the VPC network for private IP
  }

  # Ensure VPC peering for private service access is completed
  module_depends_on = [module.private-service-access.peering_completed]
}
