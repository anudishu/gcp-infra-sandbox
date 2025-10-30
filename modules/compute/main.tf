# =========================================
# COMPUTE MODULE - VM INSTANCES
# =========================================

# Local values for resource naming and configuration
locals {
  # Process VM instances with defaults
  vm_instances = {
    for key, vm in var.vm_instances : key => merge(vm, {
      name = vm.name != null ? vm.name : key
      labels = merge(
        var.default_labels,
        vm.labels,
        {
          instance-type = "compute-vm"
          vm-key       = key
        }
      )
    })
  }
}

# =========================================
# VM INSTANCES
# =========================================

# Create VM instances
resource "google_compute_instance" "vm_instances" {
  for_each = local.vm_instances

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone
  project      = var.project_id

  # Labels
  labels = each.value.labels

  # Boot disk configuration
  boot_disk {
    initialize_params {
      image = "${each.value.image_project}/${each.value.image_family}"
      size  = each.value.boot_disk_size
      type  = each.value.boot_disk_type
    }
    auto_delete = true
  }

  # Additional disks
  dynamic "attached_disk" {
    for_each = each.value.additional_disks
    content {
      source      = google_compute_disk.additional_disks["${each.key}-${attached_disk.value.name}"].self_link
      device_name = attached_disk.value.device_name
    }
  }

  # Network interface
  network_interface {
    network    = data.google_compute_network.networks[each.key].self_link
    subnetwork = data.google_compute_subnetwork.subnets[each.key].self_link
    
    # Internal IP (static if specified)
    network_ip = each.value.internal_ip

    # External IP configuration
    dynamic "access_config" {
      for_each = each.value.external_ip ? [1] : []
      content {
        # Ephemeral external IP
      }
    }
  }

  # Network tags
  tags = concat(
    each.value.network_tags,
    each.value.enable_ssh_access ? ["ssh-allowed"] : []
  )

  # Service account
  dynamic "service_account" {
    for_each = each.value.service_account != null ? [1] : []
    content {
      email  = each.value.service_account
      scopes = each.value.scopes
    }
  }

  # Metadata
  metadata = merge(
    each.value.metadata,
    {
      startup-script = each.value.startup_script
    },
    # SSH keys if provided
    length(each.value.ssh_keys) > 0 ? {
      ssh-keys = join("\n", each.value.ssh_keys)
    } : {}
  )

  # Allow stopping for updates
  allow_stopping_for_update = true

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to the startup script in metadata after creation
      metadata["startup-script"]
    ]
  }
}

# =========================================
# ADDITIONAL DISKS
# =========================================

# Create additional disks for VMs
resource "google_compute_disk" "additional_disks" {
  for_each = {
    for disk_key, disk in flatten([
      for vm_key, vm in local.vm_instances : [
        for disk in vm.additional_disks : {
          key         = "${vm_key}-${disk.name}"
          vm_key      = vm_key
          name        = "${vm.name}-${disk.name}"
          size        = disk.size
          type        = disk.type
          zone        = vm.zone
          device_name = disk.device_name != null ? disk.device_name : disk.name
        }
      ]
    ]) : disk_key.key => disk_key
  }

  name    = each.value.name
  size    = each.value.size
  type    = each.value.type
  zone    = each.value.zone
  project = var.project_id

  labels = merge(
    var.default_labels,
    {
      attached-to = each.value.vm_key
      disk-type   = "additional"
    }
  )
}

# =========================================
# DATA SOURCES
# =========================================

# Get network information for each VM
data "google_compute_network" "networks" {
  for_each = local.vm_instances
  
  name    = each.value.network_name
  project = var.project_id
}

# Get subnet information for each VM
data "google_compute_subnetwork" "subnets" {
  for_each = local.vm_instances
  
  name   = each.value.subnet_name
  region = substr(each.value.zone, 0, length(each.value.zone) - 2)  # Extract region from zone
  project = var.project_id
}

# =========================================
# FIREWALL RULES
# =========================================

# Create additional firewall rules
resource "google_compute_firewall" "compute_firewall_rules" {
  for_each = var.firewall_rules

  name        = each.key
  network     = data.google_compute_network.networks[keys(local.vm_instances)[0]].name  # Use first VM's network
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority
  project     = var.project_id

  # Source ranges
  source_ranges = each.value.source_ranges

  # Target tags
  target_tags = each.value.target_tags

  # Allow rules
  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  # Deny rules
  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
}

# =========================================
# LOAD BALANCER (OPTIONAL)
# =========================================

# Create load balancer if requested
resource "google_compute_global_forwarding_rule" "load_balancer" {
  count = var.create_load_balancer ? 1 : 0

  name       = var.load_balancer_config.name
  target     = google_compute_target_http_proxy.load_balancer[0].self_link
  port_range = "80"
  project    = var.project_id
}

resource "google_compute_target_http_proxy" "load_balancer" {
  count = var.create_load_balancer ? 1 : 0

  name    = "${var.load_balancer_config.name}-proxy"
  url_map = google_compute_url_map.load_balancer[0].self_link
  project = var.project_id
}

resource "google_compute_url_map" "load_balancer" {
  count = var.create_load_balancer ? 1 : 0

  name            = "${var.load_balancer_config.name}-map"
  default_service = google_compute_backend_service.load_balancer[0].self_link
  project         = var.project_id
}

resource "google_compute_backend_service" "load_balancer" {
  count = var.create_load_balancer ? 1 : 0

  name                  = "${var.load_balancer_config.name}-backend"
  health_checks         = [google_compute_health_check.load_balancer[0].self_link]
  session_affinity      = var.load_balancer_config.session_affinity
  enable_cdn           = var.load_balancer_config.enable_cdn
  project              = var.project_id

  # Add all VM instances as backends
  dynamic "backend" {
    for_each = local.vm_instances
    content {
      group = google_compute_instance_group.load_balancer_group[0].self_link
    }
  }
}

resource "google_compute_health_check" "load_balancer" {
  count = var.create_load_balancer ? 1 : 0

  name = "${var.load_balancer_config.name}-health-check"
  project = var.project_id

  http_health_check {
    port         = var.load_balancer_config.health_check_port
    request_path = var.load_balancer_config.health_check_path
  }
}

# Instance group for load balancer
resource "google_compute_instance_group" "load_balancer_group" {
  count = var.create_load_balancer ? 1 : 0

  name    = "${var.load_balancer_config.name}-group"
  zone    = values(local.vm_instances)[0].zone  # Use first VM's zone
  project = var.project_id

  instances = [
    for instance in google_compute_instance.vm_instances : instance.self_link
  ]

  named_port {
    name = "http"
    port = var.load_balancer_config.backend_port
  }
}
