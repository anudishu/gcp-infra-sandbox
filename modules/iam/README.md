# IAM Module

This module manages Google Cloud IAM resources including service accounts, custom roles, and IAM bindings at project, organization, and folder levels.

## Resources Created

- **Service Accounts**: Application and service identities
- **Service Account Keys**: Authentication keys for service accounts
- **Custom IAM Roles**: Project-specific custom roles
- **IAM Bindings**: Role assignments for users, groups, and service accounts
- **Workload Identity**: GKE workload identity bindings

## Features

- 🔐 **Service Account Management**: Create and manage service accounts with keys
- 🎭 **Custom Roles**: Define custom IAM roles with specific permissions
- 👥 **IAM Bindings**: Flexible IAM binding management at multiple levels
- 🔄 **Workload Identity**: GKE workload identity integration
- 🏢 **Multi-Level**: Support for project, folder, and organization IAM
- 🛡️ **Conditional IAM**: Support for conditional IAM policies

## Usage

### Basic Service Account Creation

```hcl
module "iam" {
  source = "./modules/iam"

  project_id = "my-gcp-project"

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
}
```

### Service Accounts with Keys and IAM

```hcl
module "iam" {
  source = "./modules/iam"

  project_id = "my-gcp-project"

  service_accounts = {
    "app-service-account" = {
      display_name = "Application Service Account"
      description  = "Service account for application workloads"
      
      # Create keys
      keys = [{
        key_id = "key1"
      }]
      
      # IAM bindings for this service account
      iam_bindings = {
        "roles/iam.serviceAccountUser" = [
          "user:developer@company.com"
        ]
      }
    }
  }

  # Project-level IAM bindings
  project_iam_bindings = {
    "roles/storage.objectViewer" = {
      members = [
        "serviceAccount:app-service-account@my-gcp-project.iam.gserviceaccount.com"
      ]
    }
  }
}
```

### Custom Roles

```hcl
module "iam" {
  source = "./modules/iam"

  project_id = "my-gcp-project"

  custom_roles = {
    "custom_app_role" = {
      title       = "Custom Application Role"
      description = "Custom role for application with specific permissions"
      permissions = [
        "storage.objects.get",
        "storage.objects.list",
        "compute.instances.get",
        "compute.instances.list"
      ]
    }
  }

  service_accounts = {
    "app-service-account" = {
      display_name = "Application Service Account"
    }
  }

  project_iam_bindings = {
    "projects/my-gcp-project/roles/custom_app_role" = {
      members = [
        "serviceAccount:app-service-account@my-gcp-project.iam.gserviceaccount.com"
      ]
    }
  }
}
```

### Workload Identity (GKE Integration)

```hcl
module "iam" {
  source = "./modules/iam"

  project_id = "my-gcp-project"

  service_accounts = {
    "gke-workload-sa" = {
      display_name = "GKE Workload Service Account"
      description  = "Service account for GKE workloads"
    }
  }

  workload_identity_bindings = {
    "app-workload-binding" = {
      service_account = "gke-workload-sa"
      namespace       = "default"
      ksa_name       = "app-ksa"
    }
  }

  project_iam_bindings = {
    "roles/storage.objectViewer" = {
      members = [
        "serviceAccount:gke-workload-sa@my-gcp-project.iam.gserviceaccount.com"
      ]
    }
  }
}
```

### Conditional IAM

```hcl
module "iam" {
  source = "./modules/iam"

  project_id = "my-gcp-project"

  service_accounts = {
    "conditional-sa" = {
      display_name = "Conditional Service Account"
    }
  }

  project_iam_members = [
    {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:conditional-sa@my-gcp-project.iam.gserviceaccount.com"
      condition = {
        title       = "Time-based access"
        description = "Only allow access during business hours"
        expression  = "request.time.getHours() >= 9 && request.time.getHours() <= 17"
      }
    }
  ]
}
```

### Organization and Folder IAM

```hcl
module "iam" {
  source = "./modules/iam"

  project_id      = "my-gcp-project"
  organization_id = "123456789012"
  folder_id      = "folders/123456789"

  service_accounts = {
    "org-admin-sa" = {
      display_name = "Organization Admin Service Account"
    }
  }

  organization_iam_bindings = {
    "roles/resourcemanager.organizationViewer" = {
      members = [
        "serviceAccount:org-admin-sa@my-gcp-project.iam.gserviceaccount.com"
      ]
    }
  }

  folder_iam_bindings = {
    "roles/resourcemanager.folderViewer" = {
      members = [
        "serviceAccount:org-admin-sa@my-gcp-project.iam.gserviceaccount.com"
      ]
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP project ID | `string` | n/a | yes |
| service_accounts | Map of service accounts to create | `map(object)` | `{}` | no |
| custom_roles | Map of custom roles to create | `map(object)` | `{}` | no |
| project_iam_bindings | Project-level IAM bindings | `map(object)` | `{}` | no |
| workload_identity_bindings | Workload Identity bindings | `map(object)` | `{}` | no |
| organization_id | Organization ID for org-level IAM | `string` | `""` | no |
| folder_id | Folder ID for folder-level IAM | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_accounts | Complete service account information |
| service_account_emails | Service account email addresses |
| service_account_keys | Service account key information |
| custom_roles | Custom role information |
| workload_identity_bindings | Workload Identity binding information |

## Common IAM Roles

The module includes a reference map of common IAM roles:

### Compute Roles
- `roles/compute.admin` - Full control over Compute Engine
- `roles/compute.instanceAdmin.v1` - Instance administration
- `roles/compute.networkAdmin` - Network administration

### Storage Roles
- `roles/storage.admin` - Full control over Cloud Storage
- `roles/storage.objectAdmin` - Object administration
- `roles/storage.objectViewer` - Object viewing

### Project Roles
- `roles/owner` - Full project access
- `roles/editor` - Edit access to all resources
- `roles/viewer` - Read-only access to all resources

## Best Practices

1. **Least Privilege**: Grant minimum necessary permissions
2. **Service Account Naming**: Use descriptive, consistent naming
3. **Key Management**: Rotate service account keys regularly
4. **Custom Roles**: Create custom roles for specific use cases
5. **Workload Identity**: Use Workload Identity for GKE workloads
6. **Conditional IAM**: Use conditions for time-based or resource-based access
7. **Monitoring**: Monitor IAM changes and access patterns
