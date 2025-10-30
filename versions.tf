# =========================================
# TERRAFORM AND PROVIDER VERSIONS
# =========================================

terraform {
  required_version = ">= 1.5"

  # Partial backend configuration - details provided via backend config files
  # backend "gcs" {}  # Commented out temporarily for local testing

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Google Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.default_region
  zone    = var.default_zone

  # Optional: Specify credentials file path
  # credentials = file("path/to/service-account-key.json")
}

# Google Beta Provider (for beta features)
provider "google-beta" {
  project = var.project_id
  region  = var.default_region
  zone    = var.default_zone

  # Optional: Specify credentials file path
  # credentials = file("path/to/service-account-key.json")
}
