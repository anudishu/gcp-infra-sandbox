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
