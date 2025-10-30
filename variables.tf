# =========================================
# MAIN CONFIGURATION VARIABLES
# =========================================

# Project Configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "organization_id" {
  description = "The GCP organization ID (optional)"
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "The GCP folder ID (optional)"
  type        = string
  default     = ""
}

variable "default_region" {
  description = "Default region for resources"
  type        = string
  default     = "us-central1"
}

variable "default_zone" {
  description = "Default zone for resources"
  type        = string
  default     = "us-central1-a"
}

# Environment and Labeling
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "gcp-infrastructure"
}

variable "default_labels" {
  description = "Default labels to apply to all resources"
  type        = map(string)
  default = {
    managed-by  = "terraform"
    environment = "dev"
  }
}

# Network Configuration
variable "create_network" {
  description = "Whether to create network resources"
  type        = bool
  default     = true
}

variable "network_config" {
  description = "Network configuration"
  type = object({
    network_name = string
    subnets = map(object({
      ip_cidr_range            = string
      region                   = string
      description              = string
      private_ip_google_access = bool
      secondary_ranges = optional(list(object({
        range_name    = string
        ip_cidr_range = string
      })))
    }))
    enable_nat    = bool
    nat_regions   = list(string)
    enable_iap    = bool
    iap_support_email = optional(string)
  })
  default = {
    network_name = "main-vpc"
    subnets = {
      "web-subnet" = {
        ip_cidr_range            = "10.0.1.0/24"
        region                   = "us-central1"
        description              = "Subnet for web tier"
        private_ip_google_access = true
      }
      "app-subnet" = {
        ip_cidr_range            = "10.0.2.0/24"
        region                   = "us-central1"
        description              = "Subnet for application tier"
        private_ip_google_access = true
      }
      "data-subnet" = {
        ip_cidr_range            = "10.0.3.0/24"
        region                   = "us-central1"
        description              = "Subnet for data tier"
        private_ip_google_access = true
      }
    }
    enable_nat    = true
    nat_regions   = ["us-central1"]
    enable_iap    = false
    iap_support_email = ""
  }
}

# Storage Configuration
variable "create_storage" {
  description = "Whether to create storage resources"
  type        = bool
  default     = true
}

variable "storage_config" {
  description = "Storage configuration"
  type = object({
    buckets = map(object({
      location                    = string
      storage_class              = optional(string, "STANDARD")
      force_destroy              = optional(bool, false)
      uniform_bucket_level_access = optional(bool, true)
      public_access_prevention   = optional(string, "enforced")
      versioning_enabled         = optional(bool, false)
      labels                     = optional(map(string), {})
    }))
  })
  default = {
    buckets = {
      "app-data-bucket" = {
        location      = "US"
        storage_class = "STANDARD"
        versioning_enabled = true
      }
      "backup-bucket" = {
        location      = "US"
        storage_class = "COLDLINE"
      }
      "logs-bucket" = {
        location      = "US"
        storage_class = "NEARLINE"
      }
    }
  }
}

# IAM Configuration
variable "create_iam" {
  description = "Whether to create IAM resources"
  type        = bool
  default     = true
}

variable "iam_config" {
  description = "IAM configuration"
  type = object({
    service_accounts = map(object({
      display_name = string
      description  = optional(string, "")
      disabled     = optional(bool, false)
    }))
    project_iam_bindings = optional(map(object({
      members = list(string)
    })), {})
  })
  default = {
    service_accounts = {
      "app-service-account" = {
        display_name = "Application Service Account"
        description  = "Service account for application workloads"
      }
      "backup-service-account" = {
        display_name = "Backup Service Account"
        description  = "Service account for backup operations"
      }
    }
    project_iam_bindings = {}
  }
}

# =========================================
# COMPUTE CONFIGURATION
# =========================================

variable "create_compute" {
  description = "Whether to create compute resources"
  type        = bool
  default     = false
}

variable "compute_config" {
  description = "Configuration for compute resources"
  type = object({
    # VM instances configuration
    vm_instances = optional(map(object({
      name               = optional(string)       # Custom VM name (defaults to key if not provided)
      zone               = string                 # GCP zone (e.g., "us-central1-a")
      machine_type       = optional(string, "e2-medium")  # Machine type
      boot_disk_size     = optional(number, 20)  # Boot disk size in GB
      boot_disk_type     = optional(string, "pd-standard")  # Boot disk type
      image_family       = optional(string, "ubuntu-2004-lts")  # OS image family
      image_project      = optional(string, "ubuntu-os-cloud")  # Image project
      
      # Network configuration
      network_name       = string                 # VPC network name
      subnet_name        = string                 # Subnet name
      external_ip        = optional(bool, false)  # Create external IP
      internal_ip        = optional(string)       # Static internal IP (optional)
      
      # Security and access
      network_tags       = optional(list(string), [])     # Network tags for firewall rules
      service_account    = optional(string)               # Service account email
      scopes            = optional(list(string), ["cloud-platform"])  # OAuth scopes
      
      # SSH and metadata
      enable_ssh_access  = optional(bool, true)   # Enable SSH access
      ssh_keys          = optional(list(string), [])  # SSH public keys
      metadata          = optional(map(string), {})    # Custom metadata
      
      # Startup and configuration
      startup_script    = optional(string, "")    # Startup script
      
      # Additional disks
      additional_disks  = optional(list(object({
        name   = string
        size   = number
        type   = optional(string, "pd-standard")
        device_name = optional(string)
      })), [])
      
      # Labels
      labels = optional(map(string), {})
    })), {})

    # Firewall rules
    firewall_rules = optional(map(object({
      description    = string
      direction      = optional(string, "INGRESS")
      priority       = optional(number, 1000)
      source_ranges  = optional(list(string), [])
      target_tags    = optional(list(string), [])
      allow = optional(list(object({
        protocol = string
        ports    = optional(list(string), [])
      })), [])
      deny = optional(list(object({
        protocol = string
        ports    = optional(list(string), [])
      })), [])
    })), {})

    # Load balancer configuration
    create_load_balancer = optional(bool, false)
    load_balancer_config = optional(object({
      name                = optional(string, "compute-lb")
      health_check_path   = optional(string, "/")
      health_check_port   = optional(number, 80)
      backend_port        = optional(number, 80)
      session_affinity    = optional(string, "NONE")
      enable_cdn          = optional(bool, false)
    }), {
      name                = "compute-lb"
      health_check_path   = "/"
      health_check_port   = 80
      backend_port        = 80
      session_affinity    = "NONE"
      enable_cdn          = false
    })
  })
  
  default = {
    vm_instances = {}
    firewall_rules = {}
    create_load_balancer = false
    load_balancer_config = {
      name                = "compute-lb"
      health_check_path   = "/"
      health_check_port   = 80
      backend_port        = 80
      session_affinity    = "NONE"
      enable_cdn          = false
    }
  }
}
