# =========================================
# STORAGE MODULE - Cloud Storage Buckets
# =========================================

# Cloud Storage Buckets
resource "google_storage_bucket" "buckets" {
  for_each = var.buckets

  name                        = each.key
  location                    = each.value.location
  storage_class              = each.value.storage_class
  force_destroy              = each.value.force_destroy
  uniform_bucket_level_access = each.value.uniform_bucket_level_access
  public_access_prevention   = each.value.public_access_prevention

  # Labels
  labels = merge(
    var.default_labels,
    each.value.labels
  )

  # Versioning
  dynamic "versioning" {
    for_each = each.value.versioning_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules != null ? each.value.lifecycle_rules : []
    content {
      # Condition
      condition {
        age                        = lifecycle_rule.value.condition.age
        created_before            = lifecycle_rule.value.condition.created_before
        with_state               = lifecycle_rule.value.condition.with_state
        matches_storage_class    = lifecycle_rule.value.condition.matches_storage_class
        matches_prefix           = lifecycle_rule.value.condition.matches_prefix
        matches_suffix           = lifecycle_rule.value.condition.matches_suffix
        num_newer_versions       = lifecycle_rule.value.condition.num_newer_versions
        custom_time_before       = lifecycle_rule.value.condition.custom_time_before
        days_since_custom_time   = lifecycle_rule.value.condition.days_since_custom_time
        days_since_noncurrent_time = lifecycle_rule.value.condition.days_since_noncurrent_time
        noncurrent_time_before   = lifecycle_rule.value.condition.noncurrent_time_before
      }

      # Action
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
    }
  }

  # Encryption
  dynamic "encryption" {
    for_each = each.value.encryption_key != null ? [1] : []
    content {
      default_kms_key_name = each.value.encryption_key
    }
  }

  # Logging
  dynamic "logging" {
    for_each = each.value.logging != null ? [1] : []
    content {
      log_bucket        = each.value.logging.log_bucket
      log_object_prefix = each.value.logging.log_object_prefix
    }
  }

  # Website configuration
  dynamic "website" {
    for_each = each.value.website != null ? [1] : []
    content {
      main_page_suffix = each.value.website.main_page_suffix
      not_found_page   = each.value.website.not_found_page
    }
  }

  # CORS configuration
  dynamic "cors" {
    for_each = each.value.cors != null ? each.value.cors : []
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  # Retention policy
  dynamic "retention_policy" {
    for_each = each.value.retention_policy != null ? [1] : []
    content {
      retention_period = each.value.retention_policy.retention_period
      is_locked       = each.value.retention_policy.is_locked
    }
  }

  project = var.project_id
}

# Bucket IAM bindings
resource "google_storage_bucket_iam_binding" "bucket_bindings" {
  for_each = {
    for binding in local.bucket_iam_bindings : "${binding.bucket}_${binding.role}" => binding
  }

  bucket = google_storage_bucket.buckets[each.value.bucket].name
  role   = each.value.role
  members = each.value.members

  depends_on = [google_storage_bucket.buckets]
}

# Bucket IAM members (for conditional IAM)
resource "google_storage_bucket_iam_member" "bucket_members" {
  for_each = {
    for member in local.bucket_iam_members : "${member.bucket}_${member.role}_${member.member}" => member
  }

  bucket = google_storage_bucket.buckets[each.value.bucket].name
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_storage_bucket.buckets]
}

# Bucket notification (for Cloud Functions/Cloud Run triggers)
resource "google_storage_notification" "notifications" {
  for_each = var.bucket_notifications

  bucket         = google_storage_bucket.buckets[each.value.bucket].name
  topic          = each.value.topic
  payload_format = each.value.payload_format
  event_types    = each.value.event_types
  object_name_prefix = each.value.object_name_prefix

  custom_attributes = each.value.custom_attributes

  depends_on = [google_storage_bucket.buckets]
}

# Local values for IAM processing
locals {
  # Flatten bucket IAM bindings
  bucket_iam_bindings = flatten([
    for bucket_key, bucket_config in var.buckets : [
      for role, members in coalesce(bucket_config.iam_bindings, {}) : {
        bucket  = bucket_key
        role    = role
        members = members
      }
    ]
  ])

  # Flatten bucket IAM members
  bucket_iam_members = flatten([
    for bucket_key, bucket_config in var.buckets : [
      for member_config in coalesce(bucket_config.iam_members, []) : {
        bucket    = bucket_key
        role      = member_config.role
        member    = member_config.member
        condition = member_config.condition
      }
    ]
  ])
}
