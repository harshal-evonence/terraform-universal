# Database client VM for interacting with MySQL and PostgreSQL
module "instance_template_db" {
  depends_on = [google_service_account.db_client_sa, google_compute_network.vpc]
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "~> 12.0"

  region               = var.region
  project_id           = var.project_id
  subnetwork           = google_compute_subnetwork.db_subnet.self_link
  source_image_project = "debian-cloud"
  source_image         = "debian-12"
  machine_type         = "n2-standard-8"
  disk_size_gb         = 50
  disk_type            = "pd-ssd"
  service_account = {
    email  = google_service_account.db_client_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["db-client", "ssh-access"]

  startup_script = <<-EOF
    #!/bin/bash
    apt update
    apt install -y mariadb-client postgresql-client
  EOF
}

module "compute_instance_db" {
  depends_on = [module.instance_template_db]
  source     = "terraform-google-modules/vm/google//modules/compute_instance"
  version    = "~> 12.0"

  region              = var.region
  subnetwork          = google_compute_subnetwork.regional_subnet.self_link
  hostname            = "${var.environment}-database-client"
  instance_template   = module.instance_template_db.self_link
  deletion_protection = false
}
