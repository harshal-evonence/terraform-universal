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

  # Rely on release channel for version management to avoid unsupported version errors
  release_channel {
    channel = var.gke_release_channel
  }

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

  # Workload Identity (Security)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Essential addons only
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
  }

  # Network policy (Security)
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

# Spot node pool with e2-custom (2 CPU, 4GB RAM)
resource "google_container_node_pool" "spot_nodes" {
  name     = "${var.environment}-spot-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name
  project  = var.project_id

  depends_on = [
    google_container_cluster.primary
  ]

  # Node count and autoscaling
  initial_node_count = 1

  autoscaling {
    min_node_count  = 1
    max_node_count  = 10
    location_policy = "BALANCED"
  }

  # Management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node configuration
  node_config {
    machine_type = "e2-custom-2-4096"  # 2 CPU, 4GB RAM
    disk_size_gb = 100
    disk_type    = "pd-standard" # Use pd-standard to reduce SSD usage
    image_type   = "COS_CONTAINERD"
    spot         = true  # Enable spot instances

    service_account = google_service_account.gke_service_account.email

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Labels and tags
    labels = {
      environment = var.environment
      node_pool   = "spot"
    }

    tags = ["gke-node", "${var.environment}-gke-node"]

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Shielded instance config (Security)
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload metadata config
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# KMS key for GKE encryption (Security)
resource "google_kms_key_ring" "gke_keyring" {
  name     = "${var.environment}-gke-keyring"
  location = var.region
  project  = var.project_id

  depends_on = [module.enable_apis] # Ensure KMS API is enabled before creating keyring
}

resource "google_kms_crypto_key" "gke_key" {
  name            = "${var.environment}-gke-key"
  key_ring        = google_kms_key_ring.gke_keyring.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_kms_key_ring.gke_keyring, module.enable_apis] # Explicit dependency on API enablement
}