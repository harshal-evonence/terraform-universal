# terraform-universal

# Initialization (One-time during project creation)

    export PROJECT_ID=fifth-shine-459017-v7
    gcloud config set project $PROJECT_ID
    gcloud storage buckets create gs://terraform-state-$PROJECT_ID --location=us-west1 -c standard
    gcloud storage buckets update gs://terraform-state-$PROJECT_ID --versioning
    gcloud services enable compute.googleapis.com container.googleapis.com iam.googleapis.com cloudresourcemanager.googleapis.com sqladmin.googleapis.com servicenetworking.googleapis.com 
    gcloud compute firewall-rules delete default-allow-internal -q
    gcloud compute firewall-rules delete default-allow-icmp -q
    gcloud compute firewall-rules delete default-allow-rdp -q
    gcloud compute firewall-rules delete default-allow-ssh -q
    gcloud compute networks delete default -q 

# Steps (Regular)
Run these commands
    
    #Infra
    export PROJECT_ID=fifth-shine-459017-v7
    gcloud config set project $PROJECT_ID

    cd PlatformInfrastructure
    terraform init -backend-config="bucket=terraform-state-$PROJECT_ID" -reconfigure
    terraform fmt -recursive
    terraform plan --var-file=../dev.tfvars
    terraform apply --var-file=../dev.tfvars
/*
    #Services
    export PROJECT_ID=fifth-shine-459017-v7
    gcloud config set project $PROJECT_ID
    
    cd ServiceDeployment/SERVICENAME #example 
    cd ServiceDeployment/webservice
    terraform init -backend-config="bucket=terraform-state-$PROJECT_ID" -reconfigure
    terraform fmt -recursive
    terraform plan --var-file=../../dev.tfvars
    terraform apply --var-file=../../dev.tfvars

    #SphereDx - Stack Enabled
    export PROJECT_ID=fifth-shine-459017-v7
    gcloud config set project $PROJECT_ID
    
    cd SphereDx
    terraform init -backend-config=config/dev/default/spheredx-default.gcs.tfbackend -reconfigure
    terraform fmt -recursive
    terraform plan --var-file=config/dev/dev.tfvars --var-file=config/dev/default/spheredx-default.tfvars
    terraform apply --var-file=config/dev/dev.tfvars --var-file=config/dev/default/spheredx-default.tfvars

    #For a new release(example)
    terraform init -backend-config=config/dev/nextrelease/spheredx-nextrelease.gcs.tfbackend -reconfigure
    terraform plan --var-file=config/dev/dev.tfvars --var-file=config/dev/nextrelease/spheredx-nextrelease.tfvars
    terraform apply --var-file=config/dev/dev.tfvars --var-file=config/dev/nextrelease/spheredx-nextrelease.tfvars    
*/

# Folder Structure
    ├── dev.tfvars
    └── platforminfra
        ├── artifact-registry.tf
        ├── code-refactor-vm.tf
        ├── compute-engine.tf
        ├── enable-apis.tf
        ├── firewall.tf
        ├── gke.tf
        ├── iam.tf
        ├── mysql.tf
        ├── nat.tf
        ├── network.tf
        ├── output.tf
        ├── postgresql.tf
        ├── provider.tf
        ├── random.tf
        ├── redis.tf
        ├── storage.tf
        ├── variables.tf
        └── version.tf


