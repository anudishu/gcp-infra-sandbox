# =========================================
# IAM MODULE OUTPUTS
# =========================================

output "service_accounts" {
  description = "Map of service account information"
  value = {
    for k, v in google_service_account.service_accounts : k => {
      id           = v.id
      name         = v.name
      email        = v.email
      unique_id    = v.unique_id
      display_name = v.display_name
      description  = v.description
      disabled     = v.disabled
    }
  }
}

output "service_account_emails" {
  description = "Map of service account emails"
  value = {
    for k, v in google_service_account.service_accounts : k => v.email
  }
}

output "service_account_keys" {
  description = "Map of service account key information"
  value = {
    for k, v in google_service_account_key.service_account_keys : k => {
      id               = v.id
      name             = v.name
      key_algorithm    = v.key_algorithm
      private_key_type = v.private_key_type
      public_key_type  = v.public_key_type
      public_key_data  = v.public_key_data
      valid_after      = v.valid_after
      valid_before     = v.valid_before
    }
  }
  sensitive = true
}

output "service_account_private_keys" {
  description = "Map of service account private keys (base64 encoded)"
  value = {
    for k, v in google_service_account_key.service_account_keys : k => v.private_key
  }
  sensitive = true
}

output "custom_roles" {
  description = "Map of custom role information"
  value = {
    for k, v in google_project_iam_custom_role.custom_roles : k => {
      id          = v.id
      name        = v.name
      title       = v.title
      description = v.description
      permissions = v.permissions
      stage       = v.stage
      deleted     = v.deleted
    }
  }
}

output "project_iam_bindings" {
  description = "Map of project IAM binding information"
  value = {
    for k, v in google_project_iam_binding.project_bindings : k => {
      id      = v.id
      project = v.project
      role    = v.role
      members = v.members
      etag    = v.etag
    }
  }
}

output "workload_identity_bindings" {
  description = "Map of Workload Identity binding information"
  value = {
    for k, v in google_service_account_iam_member.workload_identity : k => {
      id                 = v.id
      service_account_id = v.service_account_id
      role              = v.role
      member            = v.member
      etag              = v.etag
    }
  }
}
