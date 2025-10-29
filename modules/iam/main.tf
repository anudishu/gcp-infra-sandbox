# =========================================
# IAM MODULE - Service Accounts, Roles, Bindings
# =========================================

# Service Accounts
resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
  disabled     = each.value.disabled

  project = var.project_id
}

# Service Account Keys
resource "google_service_account_key" "service_account_keys" {
  for_each = {
    for key in local.service_account_keys : "${key.account_id}_${key.key_id}" => key
  }

  service_account_id = google_service_account.service_accounts[each.value.account_id].name
  key_algorithm     = each.value.key_algorithm
  private_key_type  = each.value.private_key_type
  public_key_type   = each.value.public_key_type
}

# Custom IAM Roles
resource "google_project_iam_custom_role" "custom_roles" {
  for_each = var.custom_roles

  role_id     = each.key
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage

  project = var.project_id
}

# Project IAM Bindings (for roles with multiple members)
resource "google_project_iam_binding" "project_bindings" {
  for_each = var.project_iam_bindings

  project = var.project_id
  role    = each.key
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Project IAM Members (for individual member assignments)
resource "google_project_iam_member" "project_members" {
  for_each = {
    for member in local.project_iam_members : "${member.role}_${member.member}" => member
  }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Service Account IAM Bindings
resource "google_service_account_iam_binding" "service_account_bindings" {
  for_each = {
    for binding in local.service_account_iam_bindings : "${binding.account_id}_${binding.role}" => binding
  }

  service_account_id = google_service_account.service_accounts[each.value.account_id].name
  role              = each.value.role
  members           = each.value.members

  depends_on = [google_service_account.service_accounts]
}

# Service Account IAM Members
resource "google_service_account_iam_member" "service_account_members" {
  for_each = {
    for member in local.service_account_iam_members : "${member.account_id}_${member.role}_${member.member}" => member
  }

  service_account_id = google_service_account.service_accounts[each.value.account_id].name
  role              = each.value.role
  member            = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_service_account.service_accounts]
}

# Workload Identity binding (for GKE)
resource "google_service_account_iam_member" "workload_identity" {
  for_each = var.workload_identity_bindings

  service_account_id = google_service_account.service_accounts[each.value.service_account].name
  role              = "roles/iam.workloadIdentityUser"
  member            = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.namespace}/${each.value.ksa_name}]"

  depends_on = [google_service_account.service_accounts]
}

# Organization IAM Bindings (if organization_id is provided)
resource "google_organization_iam_binding" "organization_bindings" {
  for_each = var.organization_id != "" ? var.organization_iam_bindings : {}

  org_id  = var.organization_id
  role    = each.key
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Folder IAM Bindings (if folder_id is provided)
resource "google_folder_iam_binding" "folder_bindings" {
  for_each = var.folder_id != "" ? var.folder_iam_bindings : {}

  folder  = var.folder_id
  role    = each.key
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Local values for processing IAM configurations
locals {
  # Flatten service account keys
  service_account_keys = flatten([
    for account_id, account_config in var.service_accounts : [
      for key_config in coalesce(account_config.keys, []) : {
        account_id       = account_id
        key_id          = key_config.key_id
        key_algorithm   = key_config.key_algorithm
        private_key_type = key_config.private_key_type
        public_key_type = key_config.public_key_type
      }
    ]
  ])

  # Flatten project IAM members
  project_iam_members = flatten([
    for member_config in var.project_iam_members : {
      role      = member_config.role
      member    = member_config.member
      condition = member_config.condition
    }
  ])

  # Flatten service account IAM bindings
  service_account_iam_bindings = flatten([
    for account_id, account_config in var.service_accounts : [
      for role, members in coalesce(account_config.iam_bindings, {}) : {
        account_id = account_id
        role       = role
        members    = members
      }
    ]
  ])

  # Flatten service account IAM members
  service_account_iam_members = flatten([
    for account_id, account_config in var.service_accounts : [
      for member_config in coalesce(account_config.iam_members, []) : {
        account_id = account_id
        role       = member_config.role
        member     = member_config.member
        condition  = member_config.condition
      }
    ]
  ])
}
