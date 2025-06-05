# Database and GKE client VM for interacting with MySQL, PostgreSQL, and GKE
module "instance_template_client" {
  depends_on = [google_service_account.db_client_sa, google_compute_network.vpc]
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "~> 12.0"

  region               = var.region
  project_id           = var.project_id
  subnetwork           = google_compute_subnetwork.regional_subnet.self_link 
  source_image_project = "debian-cloud"
  source_image         = "debian-12"
  machine_type         = "n2-standard-8"
  disk_size_gb         = 100 # Reduced from 500 GB to mitigate SSD quota issues
  disk_type            = "pd-ssd"
  service_account = {
    email  = google_service_account.db_client_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["db-client", "gke-client", "ssh-access"]

  # Install tools for both database and GKE interactions
  startup_script = <<-EOF
    #!/bin/bash
    apt update
    apt install -y mariadb-client postgresql-client kubectl google-cloud-cli-gke-gcloud-auth-plugin
  EOF
}

module "compute_instance_client" {
  depends_on = [module.instance_template_client]
  source     = "terraform-google-modules/vm/google//modules/compute_instance"
  version    = "~> 12.0"

  region              = var.region
  subnetwork          = google_compute_subnetwork.regional_subnet.self_link
  subnetwork_project  = var.project_id
  hostname            = "${var.environment}-client-vm" # Unified hostname for clarity
  instance_template   = module.instance_template_client.self_link
  deletion_protection = false
}