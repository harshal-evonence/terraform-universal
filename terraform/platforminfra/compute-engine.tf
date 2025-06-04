resource "google_compute_instance" "confidential_vm" {
  name         = "${var.environment}-confidential-vm"
  machine_type = var.confidential_vm_machine_type
  zone         = var.confidential_vm_zone
  project      = var.project_id

  confidential_instance_config {
    enable_confidential_compute = true
  }

  boot_disk {
    initialize_params {
      image = "projects/confidential-computing/global/images/confidential-ubuntu-2004-lts"
      size  = var.confidential_vm_disk_size
      type  = "pd-ssd"
    }
    auto_delete = true
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.regional_subnet.id
  }

  tags = ["confidential-vm"]

  service_account {
    email  = google_service_account.compute_sa.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  # metadata_startup_script = file("${path.module}/scripts/startup.sh")

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_network.vpc,
    google_compute_subnetwork.regional_subnet,
    google_service_account.compute_sa,
    module.enable_apis
  ]
}
