# Provision Service Accounts for GKE, Compute, and Unified Client
resource "google_service_account" "gke_service_account" {
  depends_on   = [module.enable_apis]
  account_id   = "${var.environment}-gke-nodes"
  display_name = "GKE Node Service Account for ${var.environment}"
  project      = var.project_id
  description  = "Service account for GKE cluster nodes in ${var.environment} environment"
}

resource "google_service_account" "db_client_sa" {
  depends_on   = [module.enable_apis]
  account_id   = "${var.environment}-client-sa" # Updated name for clarity
  display_name = "Unified Client Service Account for ${var.environment}"
  project      = var.project_id
  description  = "Service account for unified GKE and database client VM in ${var.environment} environment"
}

resource "google_service_account" "compute_sa" {
  depends_on   = [module.enable_apis]
  account_id   = "${var.environment}-compute-sa"
  display_name = "Compute Instance Service Account for ${var.environment}"
  project      = var.project_id
  description  = "Service account for compute instances in ${var.environment} environment"
}

module "projects_iam_bindings" {
  depends_on = [
    google_service_account.gke_service_account,
    google_service_account.db_client_sa,
    google_service_account.compute_sa
  ]
  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "~> 8.0"

  projects = [var.project_id]

  bindings = {
    "roles/artifactregistry.reader" = [
      "serviceAccount:${google_service_account.gke_service_account.email}",
    ],
    "roles/logging.logWriter" = [
      "serviceAccount:${google_service_account.gke_service_account.email}",
      "serviceAccount:${google_service_account.compute_sa.email}",
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/monitoring.metricWriter" = [
      "serviceAccount:${google_service_account.gke_service_account.email}",
      "serviceAccount:${google_service_account.compute_sa.email}",
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/monitoring.viewer" = [
      "serviceAccount:${google_service_account.gke_service_account.email}",
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/stackdriver.resourceMetadata.writer" = [
      "serviceAccount:${google_service_account.gke_service_account.email}",
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/storage.objectViewer" = [
      "serviceAccount:${google_service_account.gke_service_account.email}",
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/container.developer" = [
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/cloudsql.client" = [
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
  
    "roles/compute.viewer" = [
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/iam.serviceAccountUser" = [
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/cloudkms.viewer" = [
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/redis.viewer" = [
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/memcache.viewer" = [
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ],
    "roles/confidentialcomputing.viewer" = [
      "serviceAccount:${google_service_account.db_client_sa.email}",
    ]
  }
}

# IAM binding for GKE to use the KMS key
resource "google_kms_crypto_key_iam_binding" "gke_key_binding" {
  crypto_key_id = google_kms_crypto_key.gke_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com",
    "serviceAccount:${google_service_account.db_client_sa.email}", # Added for unified client
  ]
}