# =========================================
# IAM MODULE VARIABLES
# =========================================

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

# Service Accounts Configuration
variable "service_accounts" {
  description = "Map of service accounts to create"
  type = map(object({
    display_name = string
    description  = optional(string, "")
    disabled     = optional(bool, false)

    # Service account keys
    keys = optional(list(object({
      key_id           = string
      key_algorithm    = optional(string, "KEY_ALG_RSA_2048")
      private_key_type = optional(string, "TYPE_GOOGLE_CREDENTIALS_FILE")
      public_key_type  = optional(string, "TYPE_X509_PEM_FILE")
    })), [])

    # IAM bindings for the service account itself
    iam_bindings = optional(map(list(string)), {})

    # IAM members for the service account itself
    iam_members = optional(list(object({
      role   = string
      member = string
      condition = optional(object({
        title       = string
        description = string
        expression  = string
      }))
    })), [])
  }))
  default = {}
}

# Custom IAM Roles
variable "custom_roles" {
  description = "Map of custom IAM roles to create"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
    stage       = optional(string, "GA")
  }))
  default = {}
}

# Project-level IAM Bindings
variable "project_iam_bindings" {
  description = "Map of project-level IAM bindings"
  type = map(object({
    members = list(string)
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }))
  }))
  default = {}
}

# Project-level IAM Members
variable "project_iam_members" {
  description = "List of project-level IAM member assignments"
  type = list(object({
    role   = string
    member = string
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }))
  }))
  default = []
}

# Organization-level IAM Bindings
variable "organization_iam_bindings" {
  description = "Map of organization-level IAM bindings"
  type = map(object({
    members = list(string)
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }))
  }))
  default = {}
}

# Folder-level IAM Bindings
variable "folder_iam_bindings" {
  description = "Map of folder-level IAM bindings"
  type = map(object({
    members = list(string)
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }))
  }))
  default = {}
}

# Workload Identity Bindings (for GKE)
variable "workload_identity_bindings" {
  description = "Map of Workload Identity bindings for GKE"
  type = map(object({
    service_account = string
    namespace       = string
    ksa_name       = string
  }))
  default = {}
}

# Common IAM roles for reference
variable "common_roles" {
  description = "Common IAM roles for reference"
  type        = map(string)
  default = {
    # Compute roles
    compute_admin           = "roles/compute.admin"
    compute_instance_admin  = "roles/compute.instanceAdmin.v1"
    compute_network_admin   = "roles/compute.networkAdmin"
    compute_security_admin  = "roles/compute.securityAdmin"
    
    # Storage roles
    storage_admin           = "roles/storage.admin"
    storage_object_admin    = "roles/storage.objectAdmin"
    storage_object_creator  = "roles/storage.objectCreator"
    storage_object_viewer   = "roles/storage.objectViewer"
    
    # IAM roles
    iam_admin              = "roles/iam.serviceAccountAdmin"
    iam_user               = "roles/iam.serviceAccountUser"
    iam_token_creator      = "roles/iam.serviceAccountTokenCreator"
    
    # Project roles
    project_owner          = "roles/owner"
    project_editor         = "roles/editor"
    project_viewer         = "roles/viewer"
    
    # Monitoring roles
    monitoring_admin       = "roles/monitoring.admin"
    monitoring_editor      = "roles/monitoring.editor"
    monitoring_viewer      = "roles/monitoring.viewer"
    
    # Logging roles
    logging_admin          = "roles/logging.admin"
    logging_writer         = "roles/logging.logWriter"
    logging_viewer         = "roles/logging.viewer"
    
    # Container roles
    container_developer    = "roles/container.developer"
    container_admin        = "roles/container.admin"
    gke_developer         = "roles/container.developer"
    
    # Cloud SQL roles
    cloudsql_admin        = "roles/cloudsql.admin"
    cloudsql_client       = "roles/cloudsql.client"
    cloudsql_editor       = "roles/cloudsql.editor"
    
    # Security roles
    security_admin        = "roles/iam.securityAdmin"
    security_reviewer     = "roles/iam.securityReviewer"
  }
}
