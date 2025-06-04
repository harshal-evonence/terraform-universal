# Project Configuration
project_id  = "fifth-shine-459017-v7"
region      = "us-central1"
environment = "dev"

# Network Configuration
vpc_name     = "dev-vpc"
subnet_name  = "dev-vpc-subnet"
subnet_cidr  = "10.10.0.0/24"

# Storage Configuration
bucket_name  = "dev-pub"
priv_bucket  = "dev-priv"



# Database Configuration
mysql_db_name = "dev-mysql-db"
pg_db_name    = "dev-postgresql-db"

# GKE Configuration - Development (Smaller, Cost-Optimized)
gke_cluster_version     = "1.32.3-gke.1785003"
gke_release_channel     = "REGULAR"
gke_initial_node_count  = 2
gke_min_node_count      = 1
gke_max_node_count      = 5
gke_machine_type        = "n2d-standard-2"
gke_disk_size_gb        = 50

master_ipv4_cidr_block  = "172.16.0.0/28"

# Node Taints (Development - No special taints needed)
gke_node_taints = []
