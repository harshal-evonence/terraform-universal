variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet Name"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.0.0/24"
}

variable "bucket_name" {
  description = "Public Cloud Storage bucket Name"
  type        = string
}

variable "priv_bucket" {
  description = "Private Cloud Storage bucket Name"
  type        = string
}

variable "environment" {
  type        = string
  description = "The environment (e.g. dev, test, stage, prod)."
}

# GKE Variables
variable "gke_cluster_version" {
  description = "GKE cluster version"
  type        = string
  default     = "1.32.3-gke.1785003"
}

variable "gke_release_channel" {
  description = "GKE release channel"
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.gke_release_channel)
    error_message = "Release channel must be RAPID, REGULAR, or STABLE."
  }
}

variable "gke_initial_node_count" {
  description = "Initial number of nodes in the primary node pool"
  type        = number
  default     = 3
}

variable "gke_min_node_count" {
  description = "Minimum number of nodes in the primary node pool"
  type        = number
  default     = 1
}

variable "gke_max_node_count" {
  description = "Maximum number of nodes in the primary node pool"
  type        = number
  default     = 10
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "n2d-standard-2"
}

variable "gke_disk_size_gb" {
  description = "Disk size in GB for GKE nodes"
  type        = number
  default     = 100
}

variable "gke_maintenance_start_time" {
  description = "Maintenance window start time"
  type        = string
  default     = "2024-01-01T02:00:00Z"
}

variable "gke_maintenance_end_time" {
  description = "Maintenance window end time"
  type        = string
  default     = "2024-01-01T06:00:00Z"
}

variable "gke_node_taints" {
  description = "List of taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master nodes"
  type        = string
}


# Confidential VM variables 

variable "confidential_vm_machine_type" {
  description = "Machine type for confidential VM (must support confidential computing)"
  type        = string
  default     = "n2d-standard-4"
  validation {
    condition = can(regex("^n2d-", var.confidential_vm_machine_type))
    error_message = "Confidential VMs require N2D machine types."
  }
}

variable "confidential_vm_zone" {
  description = "Zone for confidential VM"
  type        = string
  default     = "us-central1-a"
}

variable "confidential_vm_disk_size" {
  description = "Boot disk size for confidential VM"
  type        = number
  default     = 50
}


# DB variables 
variable "mysql_db_name" {
  description = "MySQL database instance name"
  type        = string
}

variable "pg_db_name" {
  description = "PostgreSQL database instance name"
  type        = string
}

