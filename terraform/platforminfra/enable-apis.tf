
module "enable_apis" {
  source     = "terraform-google-modules/project-factory/google//modules/project_services"
  version    = "~> 17.0"
  project_id = var.project_id
  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudkms.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "binaryauthorization.googleapis.com",
    "gkehub.googleapis.com",
    "secretmanager.googleapis.com",
    "redis.googleapis.com",
    "cloudbuild.googleapis.com",
    "memcache.googleapis.com",           
    "confidentialcomputing.googleapis.com",
    "iamcredentials.googleapis.com"
  ]
  
  disable_services_on_destroy = false

  depends_on = [data.google_project.project]
  
}