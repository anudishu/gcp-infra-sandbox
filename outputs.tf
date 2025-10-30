# =========================================
# MAIN CONFIGURATION OUTPUTS
# =========================================

# Project Information
output "project_info" {
  description = "Project information"
  value = {
    project_id     = var.project_id
    project_name   = data.google_project.current.name
    project_number = data.google_project.current.number
    environment    = var.environment
  }
}

# Network Outputs
output "network" {
  description = "Network module outputs"
  value = var.create_network ? {
    network_id       = module.network[0].network_id
    network_name     = module.network[0].network_name
    network_self_link = module.network[0].network_self_link
    subnets         = module.network[0].subnets
    subnet_ids      = module.network[0].subnet_ids
    firewall_rules  = module.network[0].firewall_rules
    nat_gateways    = module.network[0].nat_gateways
  } : null
}

# Storage Outputs
output "storage" {
  description = "Storage module outputs"
  value = var.create_storage ? {
    buckets      = module.storage[0].buckets
    bucket_names = module.storage[0].bucket_names
    bucket_urls  = module.storage[0].bucket_urls
  } : null
}

# IAM Outputs
output "iam" {
  description = "IAM module outputs"
  value = var.create_iam ? {
    service_accounts       = module.iam[0].service_accounts
    service_account_emails = module.iam[0].service_account_emails
    custom_roles          = module.iam[0].custom_roles
  } : null
  sensitive = true
}

# Resource Summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    network_created = var.create_network
    storage_created = var.create_storage
    iam_created     = var.create_iam
    
    network_count = var.create_network ? length(var.network_config.subnets) : 0
    storage_count = var.create_storage ? length(var.storage_config.buckets) : 0
    iam_count     = var.create_iam ? length(var.iam_config.service_accounts) : 0
    
    total_resources = (
      (var.create_network ? length(var.network_config.subnets) + 1 : 0) +
      (var.create_storage ? length(var.storage_config.buckets) : 0) +
      (var.create_iam ? length(var.iam_config.service_accounts) : 0)
    )
  }
}

# Connection Information
output "connection_info" {
  description = "Connection information for created resources"
  value = {
    # Network connection info
    vpc_network = var.create_network ? module.network[0].network_name : null
    subnets = var.create_network ? [
      for subnet_name, subnet_info in module.network[0].subnets : {
        name   = subnet_info.name
        region = subnet_info.region
        cidr   = subnet_info.ip_cidr_range
      }
    ] : []

    # Storage connection info
    storage_buckets = var.create_storage ? [
      for bucket_name, bucket_info in module.storage[0].buckets : {
        name = bucket_info.name
        url  = bucket_info.url
        location = bucket_info.location
      }
    ] : []

    # Service account emails for applications
    service_account_emails = var.create_iam ? module.iam[0].service_account_emails : {}
  }
}

# Next Steps Information
output "next_steps" {
  description = "Suggested next steps and usage information"
  value = {
    network_usage = var.create_network ? [
      "Use subnet IDs for VM creation: ${join(", ", values(module.network[0].subnet_ids))}",
      "Configure firewall rules as needed for your applications",
      "Consider setting up VPN or Interconnect for hybrid connectivity"
    ] : []

    storage_usage = var.create_storage ? [
      "Access buckets using gsutil: gsutil ls gs://${join("/ gs://", values(module.storage[0].bucket_names))}",
      "Configure lifecycle policies for cost optimization",
      "Set up appropriate IAM permissions for applications"
    ] : []

    iam_usage = var.create_iam ? [
      "Download service account keys for application authentication",
      "Configure workload identity for GKE if using Kubernetes",
      "Review and adjust IAM permissions based on principle of least privilege"
    ] : []

    general_recommendations = [
      "Enable audit logging for security monitoring",
      "Set up billing alerts to monitor costs",
      "Configure backup and disaster recovery procedures",
      "Implement infrastructure monitoring and alerting",
      "Review security best practices for GCP"
    ]
  }
}

# =========================================
# COMPUTE OUTPUTS
# =========================================

output "compute" {
  description = "Compute resources information"
  value = var.create_compute ? {
    vm_instances     = module.compute[0].vm_instances
    vm_names         = module.compute[0].vm_names
    vm_internal_ips  = module.compute[0].vm_internal_ips
    vm_external_ips  = module.compute[0].vm_external_ips
    ssh_commands     = module.compute[0].ssh_commands
    additional_disks = module.compute[0].additional_disks
    firewall_rules   = module.compute[0].firewall_rules
    load_balancer    = module.compute[0].load_balancer
    summary          = module.compute[0].summary
  } : null
}

output "vm_connection_info" {
  description = "VM connection information for easy access"
  value = var.create_compute ? {
    for key, vm in module.compute[0].vm_instances : key => {
      name        = vm.name
      zone        = vm.zone
      internal_ip = vm.internal_ip
      external_ip = vm.external_ip
      ssh_internal = "gcloud compute ssh ${vm.name} --zone=${vm.zone} --internal-ip"
      ssh_external = vm.external_ip != null ? "gcloud compute ssh ${vm.name} --zone=${vm.zone}" : "No external IP available"
      console_link = "https://console.cloud.google.com/compute/instancesDetail/zones/${vm.zone}/instances/${vm.name}?project=${var.project_id}"
    }
  } : {}
}
