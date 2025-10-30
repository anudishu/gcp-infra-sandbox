# =========================================
# MAIN INFRASTRUCTURE CONFIGURATION
# Using Terraform Modules
# =========================================

# Local values for resource naming and configuration
locals {
  # Resource naming (shorter for service accounts)
  name_prefix = "${var.project_name}-${var.environment}"
  sa_prefix = "shivani-${var.environment}"
  
  # Common labels
  common_labels = merge(
    var.default_labels,
    {
      environment    = var.environment
      project       = var.project_name
      deployed-by   = "terraform"
      created-date  = formatdate("YYYY-MM-DD", timestamp())
    }
  )

  # Network configuration
  network_name = "${local.name_prefix}-${var.network_config.network_name}"
  
  # Storage bucket naming (shorter names to comply with 63 char limit)
  bucket_names = {
    for key, config in var.storage_config.buckets : key => "shivani-${var.environment}-${key}"
  }
}

# =========================================
# NETWORK MODULE
# =========================================
module "network" {
  count  = var.create_network ? 1 : 0
  source = "./modules/network"

  project_id           = var.project_id
  network_name         = local.network_name
  network_description  = "Main VPC network for ${var.project_name} ${var.environment}"

  # Subnets configuration
  subnets = {
    for key, subnet in var.network_config.subnets : "${local.name_prefix}-${key}" => {
      ip_cidr_range            = subnet.ip_cidr_range
      region                   = subnet.region
      description              = "${subnet.description} (${var.environment})"
      private_ip_google_access = subnet.private_ip_google_access
      secondary_ranges         = subnet.secondary_ranges
    }
  }

  # NAT configuration
  enable_nat    = var.network_config.enable_nat
  nat_regions   = var.network_config.nat_regions
  nat_logging   = var.environment == "prod" ? true : false

  # Default firewall rules
  firewall_rules = {
    "allow-internal" = {
      description    = "Allow internal communication"
      direction      = "INGRESS"
      priority       = 1000
      source_ranges  = ["10.0.0.0/8"]
      allow = [{
        protocol = "tcp"
        ports    = ["0-65535"]
      }, {
        protocol = "udp"
        ports    = ["0-65535"]
      }, {
        protocol = "icmp"
      }]
    }

    "allow-ssh" = {
      description    = "Allow SSH access"
      direction      = "INGRESS"
      priority       = 1000
      source_ranges  = ["0.0.0.0/0"]
      target_tags    = ["ssh-allowed"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    }

    "allow-iap-access" = {
      description    = "Allow Identity-Aware Proxy access"
      direction      = "INGRESS"
      priority       = 1000
      source_ranges  = ["35.235.240.0/20"]  # Google IAP IP range
      target_tags    = ["iap-access"]
      allow = [{
        protocol = "tcp"
        ports    = ["22", "80", "443", "3389"]  # SSH, HTTP, HTTPS, RDP
      }]
    }

    "allow-http-https" = {
      description    = "Allow HTTP and HTTPS"
      direction      = "INGRESS"
      priority       = 1000
      source_ranges  = ["0.0.0.0/0"]
      target_tags    = ["web-server"]
      allow = [{
        protocol = "tcp"
        ports    = ["80", "443"]
      }]
    }

    "deny-all-ingress" = {
      description    = "Deny all other ingress traffic"
      direction      = "INGRESS"
      priority       = 65534
      source_ranges  = ["0.0.0.0/0"]
      deny = [{
        protocol = "all"
      }]
    }
  }

  # IAP configuration
  enable_iap           = var.network_config.enable_iap
  iap_support_email    = var.network_config.iap_support_email
  iap_application_title = "${var.project_name} ${var.environment} Application"
}

# =========================================
# STORAGE MODULE
# =========================================
module "storage" {
  count  = var.create_storage ? 1 : 0
  source = "./modules/storage"

  project_id = var.project_id

  # Default labels for all buckets
  default_labels = local.common_labels

  # Buckets configuration with naming convention
  buckets = {
    for key, config in var.storage_config.buckets : local.bucket_names[key] => {
      location                    = config.location
      storage_class              = config.storage_class
      force_destroy              = config.force_destroy
      uniform_bucket_level_access = config.uniform_bucket_level_access
      public_access_prevention   = config.public_access_prevention
      versioning_enabled         = config.versioning_enabled
      
      labels = merge(
        local.common_labels,
        config.labels,
        {
          bucket-type = key
        }
      )

      # Lifecycle rules based on bucket type
      lifecycle_rules = key == "backup-bucket" ? [
        {
          condition = {
            age = 30
          }
          action = {
            type          = "SetStorageClass"
            storage_class = "ARCHIVE"
          }
        },
        {
          condition = {
            age = 2555  # 7 years
          }
          action = {
            type = "Delete"
          }
        }
      ] : key == "logs-bucket" ? [
        {
          condition = {
            age = 90
          }
          action = {
            type = "Delete"
          }
        }
      ] : []
    }
  }
}

# =========================================
# IAM MODULE
# =========================================
module "iam" {
  count  = var.create_iam ? 1 : 0
  source = "./modules/iam"

  project_id      = var.project_id
  organization_id = var.organization_id
  folder_id      = var.folder_id

  # Service accounts with shorter naming convention (max 30 chars)
  service_accounts = {
    for key, config in var.iam_config.service_accounts : "${local.sa_prefix}-${key}" => {
      display_name = "${config.display_name} (${var.environment})"
      description  = config.description
      disabled     = config.disabled
    }
  }

  # Project IAM bindings
  project_iam_bindings = merge(
    var.iam_config.project_iam_bindings,
    # Add default bindings for created service accounts
    var.create_storage ? {
      "roles/storage.objectAdmin" = {
        members = [
          "serviceAccount:${local.sa_prefix}-app-sa@${var.project_id}.iam.gserviceaccount.com"
        ]
      }
    } : {}
  )

  # Custom roles for specific use cases
  custom_roles = {
    "storage_lifecycle_manager" = {
      title       = "Storage Lifecycle Manager"
      description = "Custom role for managing storage lifecycle policies"
      permissions = [
        "storage.buckets.get",
        "storage.buckets.list",
        "storage.buckets.update",
        "storage.objects.get",
        "storage.objects.list",
        "storage.objects.delete"
      ]
    }
  }
}

# =========================================
# COMPUTE MODULE
# =========================================
module "compute" {
  count  = var.create_compute ? 1 : 0
  source = "./modules/compute"

  project_id = var.project_id

  # Default labels for all compute resources
  default_labels = local.common_labels

  # VM instances configuration
  vm_instances = var.compute_config.vm_instances

  # Additional firewall rules
  firewall_rules = var.compute_config.firewall_rules

  # Load balancer configuration
  create_load_balancer = var.compute_config.create_load_balancer
  load_balancer_config = var.compute_config.load_balancer_config

  # Dependencies - ensure network is created first
  depends_on = [module.network]
}

# =========================================
# DATA SOURCES FOR REFERENCE
# =========================================

# Current project information
data "google_project" "current" {
  project_id = var.project_id
}

# Available regions
data "google_compute_regions" "available" {
  project = var.project_id
}

# Available zones in default region
data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.default_region
}
