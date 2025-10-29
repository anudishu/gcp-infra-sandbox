# =========================================
# NETWORK MODULE - VPC, Subnets, Firewall, IAP
# =========================================

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode           = var.routing_mode
  description            = var.network_description

  delete_default_routes_on_create = var.delete_default_routes

  project = var.project_id
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name                     = each.key
  ip_cidr_range           = each.value.ip_cidr_range
  region                  = each.value.region
  network                 = google_compute_network.vpc.id
  description             = each.value.description
  private_ip_google_access = each.value.private_ip_google_access

  # Secondary IP ranges for GKE (if needed)
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges != null ? each.value.secondary_ranges : []
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  project = var.project_id
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  for_each = var.enable_nat ? toset(var.nat_regions) : toset([])

  name    = "${var.network_name}-router-${each.key}"
  region  = each.key
  network = google_compute_network.vpc.id

  project = var.project_id
}

# Cloud NAT for outbound internet access
resource "google_compute_router_nat" "nat" {
  for_each = var.enable_nat ? toset(var.nat_regions) : toset([])

  name                               = "${var.network_name}-nat-${each.key}"
  router                            = google_compute_router.router[each.key].name
  region                            = each.key
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = var.nat_logging
    filter = "ERRORS_ONLY"
  }

  project = var.project_id
}

# Firewall Rules
resource "google_compute_firewall" "rules" {
  for_each = var.firewall_rules

  name        = each.key
  network     = google_compute_network.vpc.name
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority

  # Source/Target configuration
  source_ranges      = each.value.source_ranges
  destination_ranges = each.value.destination_ranges
  source_tags        = each.value.source_tags
  target_tags        = each.value.target_tags
  target_service_accounts = each.value.target_service_accounts

  # Protocol and ports
  dynamic "allow" {
    for_each = each.value.allow != null ? each.value.allow : []
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny != null ? each.value.deny : []
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  # Logging
  log_config {
    metadata = each.value.log_config
  }

  project = var.project_id
}

# Default routes (if needed)
resource "google_compute_route" "default_routes" {
  for_each = var.routes

  name             = each.key
  network          = google_compute_network.vpc.name
  dest_range       = each.value.dest_range
  priority         = each.value.priority
  description      = each.value.description
  next_hop_gateway = each.value.next_hop_gateway
  next_hop_ip      = each.value.next_hop_ip
  next_hop_instance = each.value.next_hop_instance
  next_hop_vpn_tunnel = each.value.next_hop_vpn_tunnel
  tags             = each.value.tags

  project = var.project_id
}

# IAP Brand (required for IAP)
resource "google_iap_brand" "project_brand" {
  count = var.enable_iap ? 1 : 0

  support_email     = var.iap_support_email
  application_title = var.iap_application_title
  project          = var.project_id
}

# Backend service for IAP (example for web apps)
resource "google_compute_backend_service" "iap_backend" {
  for_each = var.enable_iap ? var.iap_backend_services : {}

  name                  = each.key
  description          = each.value.description
  protocol             = each.value.protocol
  port_name           = each.value.port_name
  timeout_sec         = each.value.timeout_sec
  enable_cdn          = each.value.enable_cdn
  health_checks       = each.value.health_checks
  load_balancing_scheme = each.value.load_balancing_scheme

  # IAP configuration
  iap {
    oauth2_client_id     = each.value.oauth2_client_id
    oauth2_client_secret = each.value.oauth2_client_secret
  }

  project = var.project_id
}

# Health check for backend services
resource "google_compute_health_check" "iap_health_check" {
  for_each = var.enable_iap ? var.iap_health_checks : {}

  name               = each.key
  description        = each.value.description
  timeout_sec        = each.value.timeout_sec
  check_interval_sec = each.value.check_interval_sec
  healthy_threshold  = each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold

  http_health_check {
    port               = each.value.port
    request_path       = each.value.request_path
    response           = each.value.response
  }

  project = var.project_id
}
