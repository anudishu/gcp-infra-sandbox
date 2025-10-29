# GCP Infrastructure - Terraform Modules

Simple, modular GCP infrastructure using Terraform for networking, storage, and IAM.

## 🚀 Quick Start

### 1. Prerequisites
- **Terraform** (>= 1.6) - [Install here](https://terraform.io/downloads)
- **Google Cloud SDK** - [Install here](https://cloud.google.com/sdk/docs/install)

### 2. Setup Authentication
```bash
# Login to GCP
gcloud auth application-default login

# Set your project (replace with your project ID)
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com storage-api.googleapis.com iam.googleapis.com cloudresourcemanager.googleapis.com
```

### 3. Configure Your Settings
Edit `terraform.tfvars` file with your project details:

```hcl
# Required: Your GCP project ID
project_id = "your-project-id-here"
```

### 4. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create the infrastructure
terraform apply
```

That's it! 🎉

## 📋 What Gets Created

### 🌐 Network Resources
- **1 VPC Network** - Main virtual network
- **2 Subnets** - Web tier (10.0.1.0/24) and App tier (10.0.2.0/24)
- **5 Firewall Rules** - HTTP/HTTPS, SSH, IAP access, Internal communication, Default deny

### 🪣 Storage Resources  
- **2 Cloud Storage Buckets** - App data and backup storage
- **Lifecycle Policies** - Automatic cost optimization

### 🔐 IAM Resources
- **2 Service Accounts** - For applications and compute resources
- **IAM Bindings** - Proper permissions for service accounts
- **Custom Roles** - Storage lifecycle management

## ⚙️ Key Features

- **Simple Configuration** - Just set your project ID in `terraform.tfvars`
- **Secure Network** - Private subnets with Google API access, no external internet
- **Cost Optimized Storage** - Standard bucket for apps, coldline for backups
- **Ready-to-Use IAM** - Service accounts with appropriate permissions
- **Sandbox Ready** - Perfect for development and testing

## 🛠️ Common Commands

```bash
# See what's currently deployed
terraform show

# Make changes to resources  
terraform plan
terraform apply

# Target specific resources
terraform apply -target=module.network
terraform apply -target=module.storage
terraform apply -target=module.iam

# Clean up everything
terraform destroy
```

## 🔧 Troubleshooting

**Error: API not enabled**
```bash
gcloud services enable compute.googleapis.com
```

**Error: Permission denied**
- Make sure you're logged in: `gcloud auth list`
- Check project: `gcloud config get-value project`

**Error: Resource already exists**
- Import existing resource: `terraform import RESOURCE_TYPE.NAME RESOURCE_ID`
- Or choose different names in `terraform.tfvars`

## 💰 Estimated Costs (Monthly)

- **Network:** FREE
- **Storage:** ~$1-5 (depends on data stored)
- **Service Accounts:** FREE
- **Total:** Very low cost for sandbox/development

## 🧹 Cleanup

When you're done testing:
```bash
terraform destroy
```

This removes all created resources to avoid ongoing charges.

---

## 📁 Project Structure

```
terraform-gcp-infrastructure/
├── README.md                # This guide
├── main.tf                  # Main configuration
├── variables.tf             # Input variables  
├── outputs.tf              # Output values
├── terraform.tfvars        # Your settings
├── terraform.tfvars.example # Example configuration
├── versions.tf             # Provider versions
└── modules/                # Reusable modules
    ├── network/            # VPC, subnets, firewall
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    ├── storage/            # Cloud Storage buckets
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    └── iam/                # Service accounts, roles
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

## 📋 Modules Overview

| Module | Purpose | Resources |
|--------|---------|-----------|
| **network** | VPC, subnets, firewall | VPC, subnets, firewall rules |
| **storage** | Cloud Storage buckets | Storage buckets with versioning, lifecycle |
| **iam** | IAM roles and permissions | Service accounts, IAM bindings |

## 🔐 Identity-Aware Proxy (IAP) Setup

**Note:** IAP requires your GCP project to be part of an organization (not available for personal projects).

If you want to enable IAP for secure VM access:

1. **Update terraform.tfvars:**
   ```hcl
   enable_iap = true
   iap_support_email = "your-email@domain.com"
   ```

2. **Tag your VMs** with `iap-access` to allow IAP connections:
   ```hcl
   tags = ["iap-access"]
   ```

3. **Connect via IAP:**
   ```bash
   gcloud compute ssh VM_NAME --zone=ZONE --tunnel-through-iap
   ```

The firewall rule `allow-iap-access` allows traffic from Google's IAP IP range (`35.235.240.0/20`) on ports:
- **22** (SSH)
- **80, 443** (HTTP/HTTPS) 
- **3389** (RDP for Windows)

## 🚀 Test Your Infrastructure

```bash
# List your buckets
gsutil ls gs://shivani-dev-app-data-bucket/ gs://shivani-dev-backup-bucket/

# Test bucket access
echo "Hello from your infrastructure!" | gsutil cp - gs://shivani-dev-app-data-bucket/test.txt

# View your networks and firewall rules
gcloud compute networks list
gcloud compute subnets list --filter="network:*main-vpc"
gcloud compute firewall-rules list --filter="network:*main-vpc"

# View service accounts
gcloud iam service-accounts list --filter="email:*dev*"
```

**Need help?** Check the module README files in `modules/` for detailed documentation.# gcp-infra-sandbox
