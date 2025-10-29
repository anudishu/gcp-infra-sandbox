# =========================================
# STORAGE MODULE VARIABLES
# =========================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "default_labels" {
  description = "Default labels to apply to all buckets"
  type        = map(string)
  default = {
    managed-by = "terraform"
  }
}

# Buckets Configuration
variable "buckets" {
  description = "Map of Cloud Storage buckets to create"
  type = map(object({
    location                    = string
    storage_class              = optional(string, "STANDARD")
    force_destroy              = optional(bool, false)
    uniform_bucket_level_access = optional(bool, true)
    public_access_prevention   = optional(string, "enforced")
    versioning_enabled         = optional(bool, false)
    labels                     = optional(map(string), {})
    encryption_key             = optional(string)

    # Lifecycle rules
    lifecycle_rules = optional(list(object({
      condition = object({
        age                        = optional(number)
        created_before            = optional(string)
        with_state               = optional(string)
        matches_storage_class    = optional(list(string))
        matches_prefix           = optional(list(string))
        matches_suffix           = optional(list(string))
        num_newer_versions       = optional(number)
        custom_time_before       = optional(string)
        days_since_custom_time   = optional(number)
        days_since_noncurrent_time = optional(number)
        noncurrent_time_before   = optional(string)
      })
      action = object({
        type          = string
        storage_class = optional(string)
      })
    })))

    # Logging
    logging = optional(object({
      log_bucket        = string
      log_object_prefix = optional(string)
    }))

    # Website configuration
    website = optional(object({
      main_page_suffix = optional(string, "index.html")
      not_found_page   = optional(string, "404.html")
    }))

    # CORS configuration
    cors = optional(list(object({
      origin          = list(string)
      method          = list(string)
      response_header = optional(list(string))
      max_age_seconds = optional(number)
    })))

    # Retention policy
    retention_policy = optional(object({
      retention_period = number
      is_locked       = optional(bool, false)
    }))

    # IAM bindings (role -> list of members)
    iam_bindings = optional(map(list(string)))

    # IAM members (for conditional IAM)
    iam_members = optional(list(object({
      role   = string
      member = string
      condition = optional(object({
        title       = string
        description = string
        expression  = string
      }))
    })))
  }))
  default = {}
}

# Bucket Notifications
variable "bucket_notifications" {
  description = "Map of bucket notifications to create"
  type = map(object({
    bucket             = string
    topic              = string
    payload_format     = optional(string, "JSON_API_V1")
    event_types        = optional(list(string), ["OBJECT_FINALIZE"])
    object_name_prefix = optional(string)
    custom_attributes  = optional(map(string))
  }))
  default = {}
}

# Common storage classes
variable "storage_classes" {
  description = "Available storage classes for reference"
  type        = map(string)
  default = {
    standard     = "STANDARD"
    nearline     = "NEARLINE"
    coldline     = "COLDLINE"
    archive      = "ARCHIVE"
    multi_regional = "MULTI_REGIONAL"
    regional     = "REGIONAL"
  }
}
