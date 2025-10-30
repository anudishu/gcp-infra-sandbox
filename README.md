# GCP Infrastructure - Terraform

**Production-ready GCP infrastructure deployed with Terraform modules.**

## 🌐 Live Infrastructure

**✅ Successfully Deployed**
- **Web Server**: http://34.27.182.72 (shivani-web-server)
- **Project**: probable-cove-474504-p0
- **Environment**: Development

## 🏗️ Infrastructure Components

| Module | Resources | Status |
|--------|-----------|--------|
| **Network** | VPC, subnets, firewall rules | ✅ |
| **Storage** | 2 Cloud Storage buckets | ✅ |
| **IAM** | Service accounts, roles | ✅ |
| **Compute** | 1 VM (e2-medium, RHEL) | ✅ |

## 🚀 Quick Start

### Prerequisites
- [Terraform](https://terraform.io/downloads) >= 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

### Authentication
```bash
gcloud auth application-default login
gcloud config set project probable-cove-474504-p0
```

### Deploy
```bash
terraform init
terraform plan
terraform apply
```

## 📝 Configuration

Edit `terraform.tfvars` to customize:

```hcl
# Basic settings
project_id = "your-project-id"
environment = "dev"

# Enable/disable modules
create_network = true
create_storage = true
create_iam = true
create_compute = true
```

## 🔧 Management

### View Infrastructure
```bash
terraform output                 # All outputs
terraform show                  # Current state
```

### Connect to Web Server
```bash
gcloud compute ssh shivani-web-server --zone=us-central1-a
```

### Manage Storage
```bash
gsutil ls gs://shivani-dev-app-data-bucket/
gsutil cp file.txt gs://shivani-dev-app-data-bucket/
```

### Cost Control
```bash
# Stop VM (saves ~$25/month)
gcloud compute instances stop shivani-web-server --zone=us-central1-a

# Restart when needed
gcloud compute instances start shivani-web-server --zone=us-central1-a
```

## 🧹 Cleanup

```bash
# Remove everything
terraform destroy

# Remove only compute resources
terraform destroy -target=module.compute
```

## 📋 What's Included

- **Network**: VPC with web/app subnets, firewall rules
- **Storage**: App data bucket + backup bucket with lifecycle policies
- **IAM**: Service accounts with appropriate permissions
- **Compute**: RHEL web server with Nginx pre-installed

## 🔧 Troubleshooting

**Permission Issues**
```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

**Network Not Found**
```bash
# Check actual network names
gcloud compute networks list
gcloud compute networks subnets list
```

**Image Issues**
Change in `terraform.tfvars`:
```hcl
image_family = "rhel-9"           # Instead of rhel-10
image_family = "ubuntu-2204-lts"  # Or use Ubuntu
```

## 📁 Project Structure

```
terraform-gcp-infrastructure/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf             # Outputs
├── terraform.tfvars       # Your settings
├── versions.tf            # Provider configuration
└── modules/
    ├── compute/           # VM instances
    ├── network/           # VPC, subnets, firewall
    ├── storage/           # Cloud Storage buckets
    └── iam/               # Service accounts, roles
```

## 💰 Monthly Costs

- **Compute (e2-medium)**: ~$25 (if running 24/7)
- **Storage**: ~$1-5
- **Network**: Free
- **Total**: ~$26-30/month

## 🚀 Next Steps

1. **Test**: Visit http://34.27.182.72
2. **SSH**: Connect to your server
3. **Expand**: Add load balancer, database, monitoring
4. **Production**: Configure remote state backend

---

**Need help?** Check module documentation in `modules/*/README.md`