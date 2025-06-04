#Cloud SQL for MySQL 8.0 with Private IP Address
module "private-service-access" {
  depends_on = [google_compute_network.vpc]
  source     = "terraform-google-modules/sql-db/google//modules/private_service_access"
  version    = "~> 23.0"

  project_id      = var.project_id
  vpc_network     = google_compute_network.vpc.name
  deletion_policy = "ABANDON"
}

module "safer-mysql-db" {
  depends_on = [google_compute_network.vpc]
  source     = "terraform-google-modules/sql-db/google//modules/safer_mysql"
  version    = "~> 23.0"


  name                 = var.mysql_db_name
  random_instance_name = true
  project_id           = var.project_id

  deletion_protection = true

  database_version = "MYSQL_8_0"
  region           = var.region
  tier             = "db-n1-standard-1"

  database_flags = [
    {
      name  = "cloudsql_iam_authentication"
      value = "on"
    },
  ]

  assign_public_ip   = false
  vpc_network        = google_compute_network.vpc.self_link
  allocated_ip_range = module.private-service-access.google_compute_global_address_name

  // Optional: used to enforce ordering in the creation of resources.
  module_depends_on = [module.private-service-access.peering_completed]
}