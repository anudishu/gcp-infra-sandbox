# =========================================
# NETWORK MODULE OUTPUTS
# =========================================

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "Map of subnet information"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => {
      id                       = v.id
      name                     = v.name
      ip_cidr_range           = v.ip_cidr_range
      region                  = v.region
      self_link               = v.self_link
      private_ip_google_access = v.private_ip_google_access
      secondary_ip_range      = v.secondary_ip_range
    }
  }
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => v.id
  }
}

output "subnet_self_links" {
  description = "Map of subnet self links"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => v.self_link
  }
}

output "firewall_rules" {
  description = "Map of firewall rule information"
  value = {
    for k, v in google_compute_firewall.rules : k => {
      id        = v.id
      name      = v.name
      self_link = v.self_link
    }
  }
}

output "nat_gateways" {
  description = "Map of Cloud NAT gateway information"
  value = {
    for k, v in google_compute_router_nat.nat : k => {
      id     = v.id
      name   = v.name
      region = v.region
    }
  }
}

output "routes" {
  description = "Map of custom route information"
  value = {
    for k, v in google_compute_route.default_routes : k => {
      id        = v.id
      name      = v.name
      self_link = v.self_link
    }
  }
}

output "iap_brand" {
  description = "IAP brand information"
  value = var.enable_iap ? {
    name              = google_iap_brand.project_brand[0].name
    support_email     = google_iap_brand.project_brand[0].support_email
    application_title = google_iap_brand.project_brand[0].application_title
  } : null
}

output "backend_services" {
  description = "Map of backend service information for IAP"
  value = {
    for k, v in google_compute_backend_service.iap_backend : k => {
      id        = v.id
      name      = v.name
      self_link = v.self_link
    }
  }
}
