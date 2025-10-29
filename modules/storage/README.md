# Storage Module

This module creates and manages Google Cloud Storage buckets with comprehensive configuration options including lifecycle management, IAM, versioning, and notifications.

## Resources Created

- **Cloud Storage Buckets**: Primary storage buckets with full configuration
- **Bucket IAM Bindings**: Role-based access control
- **Bucket Notifications**: Event notifications to Pub/Sub topics
- **Lifecycle Rules**: Automated object lifecycle management

## Features

- 🗂️ **Multiple Storage Classes**: Standard, Nearline, Coldline, Archive
- 🔒 **Security**: Uniform bucket-level access, public access prevention
- 📝 **Versioning**: Object versioning support
- 🔄 **Lifecycle Management**: Automatic object lifecycle rules
- 🔐 **IAM Integration**: Granular access control
- 📢 **Event Notifications**: Integration with Pub/Sub
- 🌐 **Website Hosting**: Static website hosting configuration
- 📊 **Logging**: Access logging configuration

## Usage

### Basic Usage

```hcl
module "storage" {
  source = "./modules/storage"

  project_id = "my-gcp-project"

  buckets = {
    "app-data-bucket" = {
      location      = "US"
      storage_class = "STANDARD"
      versioning_enabled = true
      
      lifecycle_rules = [{
        condition = {
          age = 30
        }
        action = {
          type          = "SetStorageClass"
          storage_class = "NEARLINE"
        }
      }]
    }
    
    "backup-bucket" = {
      location      = "US"
      storage_class = "COLDLINE"
      
      lifecycle_rules = [{
        condition = {
          age = 365
        }
        action = {
          type = "Delete"
        }
      }]
    }
  }
}
```

### Advanced Usage with IAM and Notifications

```hcl
module "storage" {
  source = "./modules/storage"

  project_id = "my-gcp-project"

  buckets = {
    "secure-data-bucket" = {
      location                    = "US"
      storage_class              = "STANDARD"
      uniform_bucket_level_access = true
      public_access_prevention   = "enforced"
      versioning_enabled         = true
      encryption_key             = "projects/my-project/locations/us/keyRings/my-ring/cryptoKeys/my-key"
      
      # IAM bindings
      iam_bindings = {
        "roles/storage.objectViewer" = [
          "group:data-readers@company.com"
        ]
        "roles/storage.objectAdmin" = [
          "serviceAccount:app@my-project.iam.gserviceaccount.com"
        ]
      }
      
      # Lifecycle rules
      lifecycle_rules = [
        {
          condition = {
            age = 30
          }
          action = {
            type          = "SetStorageClass"
            storage_class = "NEARLINE"
          }
        },
        {
          condition = {
            age = 90
            matches_storage_class = ["NEARLINE"]
          }
          action = {
            type          = "SetStorageClass"
            storage_class = "COLDLINE"
          }
        }
      ]
      
      # CORS for web access
      cors = [{
        origin          = ["https://myapp.com"]
        method          = ["GET", "POST"]
        response_header = ["Content-Type"]
        max_age_seconds = 3600
      }]
    }
  }

  # Bucket notifications
  bucket_notifications = {
    "data-processing-trigger" = {
      bucket      = "secure-data-bucket"
      topic       = "projects/my-project/topics/process-data"
      event_types = ["OBJECT_FINALIZE"]
      object_name_prefix = "uploads/"
    }
  }
}
```

### Website Hosting

```hcl
module "storage" {
  source = "./modules/storage"

  project_id = "my-gcp-project"

  buckets = {
    "my-website-bucket" = {
      location      = "US"
      storage_class = "STANDARD"
      
      # Website configuration
      website = {
        main_page_suffix = "index.html"
        not_found_page   = "404.html"
      }
      
      # Make it publicly readable
      iam_bindings = {
        "roles/storage.objectViewer" = [
          "allUsers"
        ]
      }
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP project ID | `string` | n/a | yes |
| buckets | Map of buckets to create | `map(object)` | `{}` | no |
| bucket_notifications | Map of bucket notifications | `map(object)` | `{}` | no |
| default_labels | Default labels for all buckets | `map(string)` | `{"managed-by" = "terraform"}` | no |

## Outputs

| Name | Description |
|------|-------------|
| buckets | Complete bucket information |
| bucket_names | Map of bucket names |
| bucket_urls | Map of bucket URLs |
| bucket_notifications | Bucket notification information |

## Storage Classes

| Class | Use Case | Minimum Storage Duration |
|-------|----------|-------------------------|
| STANDARD | Frequently accessed data | None |
| NEARLINE | Data accessed less than once per month | 30 days |
| COLDLINE | Data accessed less than once per quarter | 90 days |
| ARCHIVE | Long-term backup and archival | 365 days |

## Best Practices

1. **Security**: Always enable uniform bucket-level access and public access prevention
2. **Lifecycle**: Use lifecycle rules to automatically transition objects to cheaper storage classes
3. **Versioning**: Enable versioning for important data
4. **Encryption**: Use customer-managed encryption keys for sensitive data
5. **IAM**: Use least privilege principle for bucket access
6. **Monitoring**: Set up notifications for important bucket events
