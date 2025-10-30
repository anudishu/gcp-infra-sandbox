# =========================================
# NETWORK MODULE VARIABLES
# =========================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "main-vpc"
}

variable "network_description" {
  description = "Description of the VPC network"
  type        = string
  default     = "Main VPC network for the project"
}

variable "routing_mode" {
  description = "The network routing mode (GLOBAL or REGIONAL)"
  type        = string
  default     = "GLOBAL"
  validation {
    condition     = contains(["GLOBAL", "REGIONAL"], var.routing_mode)
    error_message = "Routing mode must be either GLOBAL or REGIONAL."
  }
}

variable "delete_default_routes" {
  description = "Whether to delete the default routes"
  type        = bool
  default     = false
}

# Subnets Configuration
variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    ip_cidr_range            = string
    region                   = string
    description              = string
    private_ip_google_access = bool
    secondary_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })))
  }))
  default = {}
}

# NAT Configuration
variable "enable_nat" {
  description = "Enable Cloud NAT for outbound internet access"
  type        = bool
  default     = true
}

variable "nat_regions" {
  description = "List of regions where NAT should be created"
  type        = list(string)
  default     = ["us-central1"]
}

variable "nat_logging" {
  description = "Enable NAT logging"
  type        = bool
  default     = false
}

# Firewall Rules
variable "firewall_rules" {
  description = "Map of firewall rules to create"
  type = map(object({
    description               = string
    direction                = string
    priority                 = number
    source_ranges            = optional(list(string))
    destination_ranges       = optional(list(string))
    source_tags              = optional(list(string))
    target_tags              = optional(list(string))
    target_service_accounts  = optional(list(string))
    log_config               = optional(string, "EXCLUDE_ALL_METADATA")
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
  }))
  default = {}
}

# Routes
variable "routes" {
  description = "Map of custom routes to create"
  type = map(object({
    dest_range           = string
    priority            = number
    description         = optional(string)
    next_hop_gateway    = optional(string)
    next_hop_ip         = optional(string)
    next_hop_instance   = optional(string)
    next_hop_vpn_tunnel = optional(string)
    tags                = optional(list(string))
  }))
  default = {}
}

# IAP Configuration
variable "enable_iap" {
  description = "Enable Identity Aware Proxy"
  type        = bool
  default     = false
}

variable "iap_support_email" {
  description = "Support email for IAP brand"
  type        = string
  default     = ""
}

variable "iap_application_title" {
  description = "Application title for IAP brand"
  type        = string
  default     = "IAP Protected Application"
}

variable "iap_backend_services" {
  description = "Map of backend services for IAP"
  type = map(object({
    description          = string
    protocol            = string
    port_name           = string
    timeout_sec         = number
    enable_cdn          = bool
    health_checks       = list(string)
    load_balancing_scheme = string
    oauth2_client_id    = string
    oauth2_client_secret = string
  }))
  default = {}
}

variable "iap_health_checks" {
  description = "Map of health checks for IAP backend services"
  type = map(object({
    description         = string
    timeout_sec        = number
    check_interval_sec = number
    healthy_threshold  = number
    unhealthy_threshold = number
    port               = number
    request_path       = string
    response           = optional(string)
  }))
  default = {}
}
