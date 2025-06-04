# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.environment}-gke-cluster"
  location = var.region # Regional cluster for high availability
  project  = var.project_id

  # Network configuration
  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.regional_subnet.self_link

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Cluster version
  min_master_version = var.gke_cluster_version

  # Enable VPC-native networking
  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.subnet_name}-pods"
    services_secondary_range_name = "${var.subnet_name}-services"
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = false
    }
  }

  # Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.subnet_cidr
      display_name = "VPC Subnet"
    }
    cidr_blocks {
      cidr_block   = var.master_ipv4_cidr_block
      display_name = "Master Subnet"
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Confidential Nodes
  confidential_nodes {
    enabled = true
  }

  # Vertical Pod Autoscaling
  vertical_pod_autoscaling {
    enabled = true
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    dns_cache_config {
      enabled = true
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    gke_backup_agent_config {
      enabled = true
    }

    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  # Network policy
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Logging and monitoring
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "APISERVER"
    ]
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "STORAGE",
      "POD",
      "DEPLOYMENT",
      "STATEFULSET",
      "DAEMONSET",
      "HPA"
    ]

    managed_prometheus {
      enabled = true
    }
  }

  # Security configurations
  enable_shielded_nodes = true

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.gke_key.id
  }

  # Release channel
  release_channel {
    channel = var.gke_release_channel
  }

  # Resource labels
  resource_labels = {
    environment = var.environment
    managed_by  = "terraform"
    team        = "platform"
  }

  depends_on = [
    google_compute_network.vpc,
    google_compute_subnetwork.regional_subnet,
    module.enable_apis
  ]
}

# Primary node pool
resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.environment}-primary-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name
  project  = var.project_id

  depends_on = [
    google_container_cluster.primary
  ]

  # Node count and autoscaling
  initial_node_count = var.gke_initial_node_count

  autoscaling {
    min_node_count       = var.gke_min_node_count
    max_node_count       = var.gke_max_node_count
    location_policy      = "BALANCED"
    total_min_node_count = var.gke_min_node_count
    total_max_node_count = var.gke_max_node_count
  }

  # Management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = 1
    max_unavailable = 0
    blue_green_settings {
      standard_rollout_policy {
        batch_percentage    = 1.0
        batch_soak_duration = "0s"
      }
      node_pool_soak_duration = "0s"
    }
  }

  # Node configuration
  node_config {
    machine_type    = var.gke_machine_type
    disk_size_gb    = var.gke_disk_size_gb
    disk_type       = "pd-ssd"
    image_type      = "COS_CONTAINERD"
    service_account = google_service_account.gke_service_account.email

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Labels and tags
    labels = {
      environment = var.environment
      node_pool   = "primary"
    }

    tags = ["gke-node", "${var.environment}-gke-node"]

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload metadata config
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Taint for specific workloads (optional)
    dynamic "taint" {
      for_each = var.gke_node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  # Network configuration
  network_config {
    create_pod_range = false
  }
}

# KMS key for GKE encryption
resource "google_kms_key_ring" "gke_keyring" {
  name     = "${var.environment}-gke-keyring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "gke_key" {
  name            = "${var.environment}-gke-key"
  key_ring        = google_kms_key_ring.gke_keyring.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# GKE Client VM for Kubernetes deployments
module "instance_template_gke_client" {
  depends_on = [google_service_account.gke_client_sa, google_compute_network.vpc]
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "~> 12.0"

  region               = var.region
  project_id           = var.project_id
  subnetwork           = google_compute_subnetwork.regional_subnet.self_link
  source_image_project = "debian-cloud"
  source_image         = "debian-12"
  machine_type         = "n2-standard-8"
  disk_size_gb         = 500
  disk_type            = "pd-ssd"
  service_account = {
    email  = google_service_account.gke_client_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["gke-client", "ssh-access"]

  startup_script = <<-EOF
    #!/bin/bash
    apt update
    apt install -y kubectl google-cloud-cli-gke-gcloud-auth-plugin
  EOF
}

module "compute_instance_gke_client" {
  depends_on = [module.instance_template_gke_client]
  source     = "terraform-google-modules/vm/google//modules/compute_instance"
  version    = "~> 12.0"

  region              = var.region
  subnetwork          = google_compute_subnetwork.regional_subnet.self_link
  hostname            = "${var.environment}-gke-client"
  instance_template   = module.instance_template_gke_client.self_link
  deletion_protection = false
}