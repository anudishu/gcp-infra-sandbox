# =========================================
# COMPUTE MODULE OUTPUTS
# =========================================

# =========================================
# VM INSTANCES OUTPUTS
# =========================================

output "vm_instances" {
  description = "Map of VM instance information"
  value = {
    for key, instance in google_compute_instance.vm_instances : key => {
      id                = instance.id
      name              = instance.name
      machine_type      = instance.machine_type
      zone              = instance.zone
      self_link         = instance.self_link
      internal_ip       = instance.network_interface[0].network_ip
      external_ip       = length(instance.network_interface[0].access_config) > 0 ? instance.network_interface[0].access_config[0].nat_ip : null
      network           = instance.network_interface[0].network
      subnetwork        = instance.network_interface[0].subnetwork
      status            = instance.current_status
      tags              = instance.tags
      labels            = instance.labels
      cpu_platform      = instance.cpu_platform
      min_cpu_platform  = instance.min_cpu_platform
      # creation_timestamp = instance.creation_timestamp  # Not available in resource
    }
  }
}

output "vm_names" {
  description = "List of VM instance names"
  value       = [for instance in google_compute_instance.vm_instances : instance.name]
}

output "vm_internal_ips" {
  description = "Map of VM internal IP addresses"
  value = {
    for key, instance in google_compute_instance.vm_instances : key => instance.network_interface[0].network_ip
  }
}

output "vm_external_ips" {
  description = "Map of VM external IP addresses (if any)"
  value = {
    for key, instance in google_compute_instance.vm_instances : key => (
      length(instance.network_interface[0].access_config) > 0 ? 
      instance.network_interface[0].access_config[0].nat_ip : null
    )
  }
}

output "vm_self_links" {
  description = "Map of VM self links"
  value = {
    for key, instance in google_compute_instance.vm_instances : key => instance.self_link
  }
}

# =========================================
# SSH CONNECTION STRINGS
# =========================================

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = {
    for key, instance in google_compute_instance.vm_instances : key => {
      internal = "gcloud compute ssh ${instance.name} --zone=${instance.zone} --internal-ip"
      external = length(instance.network_interface[0].access_config) > 0 ? "gcloud compute ssh ${instance.name} --zone=${instance.zone}" : "No external IP - use internal connection"
    }
  }
}

# =========================================
# ADDITIONAL DISKS OUTPUTS
# =========================================

output "additional_disks" {
  description = "Map of additional disk information"
  value = {
    for key, disk in google_compute_disk.additional_disks : key => {
      id              = disk.id
      name            = disk.name
      size            = disk.size
      type            = disk.type
      zone            = disk.zone
      self_link       = disk.self_link
      # creation_timestamp = disk.creation_timestamp  # Not available in resource
    }
  }
}

# =========================================
# FIREWALL RULES OUTPUTS
# =========================================

output "firewall_rules" {
  description = "Map of firewall rule information"
  value = {
    for key, rule in google_compute_firewall.compute_firewall_rules : key => {
      id            = rule.id
      name          = rule.name
      description   = rule.description
      direction     = rule.direction
      priority      = rule.priority
      network       = rule.network
      source_ranges = rule.source_ranges
      target_tags   = rule.target_tags
      self_link     = rule.self_link
    }
  }
}

# =========================================
# LOAD BALANCER OUTPUTS
# =========================================

output "load_balancer" {
  description = "Load balancer information (if created)"
  value = var.create_load_balancer ? {
    forwarding_rule = {
      name      = google_compute_global_forwarding_rule.load_balancer[0].name
      ip_address = google_compute_global_forwarding_rule.load_balancer[0].ip_address
      self_link = google_compute_global_forwarding_rule.load_balancer[0].self_link
    }
    backend_service = {
      name      = google_compute_backend_service.load_balancer[0].name
      self_link = google_compute_backend_service.load_balancer[0].self_link
    }
    health_check = {
      name      = google_compute_health_check.load_balancer[0].name
      self_link = google_compute_health_check.load_balancer[0].self_link
    }
    instance_group = {
      name      = google_compute_instance_group.load_balancer_group[0].name
      self_link = google_compute_instance_group.load_balancer_group[0].self_link
    }
  } : null
}

# =========================================
# SUMMARY OUTPUTS
# =========================================

output "summary" {
  description = "Summary of created compute resources"
  value = {
    vm_count           = length(google_compute_instance.vm_instances)
    additional_disk_count = length(google_compute_disk.additional_disks)
    firewall_rule_count = length(google_compute_firewall.compute_firewall_rules)
    load_balancer_created = var.create_load_balancer
    
    vm_zones = distinct([
      for instance in google_compute_instance.vm_instances : instance.zone
    ])
    
    vm_machine_types = distinct([
      for instance in google_compute_instance.vm_instances : instance.machine_type
    ])
    
    networks_used = distinct([
      for instance in google_compute_instance.vm_instances : instance.network_interface[0].network
    ])
  }
}
