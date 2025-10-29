# =========================================
# STORAGE MODULE OUTPUTS
# =========================================

output "buckets" {
  description = "Map of bucket information"
  value = {
    for k, v in google_storage_bucket.buckets : k => {
      id                          = v.id
      name                        = v.name
      url                         = v.url
      self_link                   = v.self_link
      location                    = v.location
      storage_class              = v.storage_class
      uniform_bucket_level_access = v.uniform_bucket_level_access
      public_access_prevention   = v.public_access_prevention
      versioning                 = v.versioning
      labels                     = v.labels
    }
  }
}

output "bucket_names" {
  description = "Map of bucket names"
  value = {
    for k, v in google_storage_bucket.buckets : k => v.name
  }
}

output "bucket_urls" {
  description = "Map of bucket URLs"
  value = {
    for k, v in google_storage_bucket.buckets : k => v.url
  }
}

output "bucket_self_links" {
  description = "Map of bucket self links"
  value = {
    for k, v in google_storage_bucket.buckets : k => v.self_link
  }
}

output "bucket_notifications" {
  description = "Map of bucket notification information"
  value = {
    for k, v in google_storage_notification.notifications : k => {
      id             = v.id
      bucket         = v.bucket
      topic          = v.topic
      payload_format = v.payload_format
      event_types    = v.event_types
    }
  }
}
