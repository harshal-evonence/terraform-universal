resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id
  description             = "VPC network for ${var.environment} environment"
}

resource "google_compute_subnetwork" "regional_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  description   = "Regional subnet for ${var.environment} environment"

  # Enable private Google access for nodes without external IPs
  private_ip_google_access = true

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "${var.subnet_name}-pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "${var.subnet_name}-services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

# Additional subnet for database instances
resource "google_compute_subnetwork" "db_subnet" {
  name          = "${var.subnet_name}-db"
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  description   = "Subnet for database instances in ${var.environment} environment"
  ip_cidr_range = "10.3.0.0/24"

  private_ip_google_access = true

}