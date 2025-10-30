# =========================================
# COMPUTE MODULE VARIABLES
# =========================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "default_labels" {
  description = "Default labels to apply to all compute resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
  }
}

# =========================================
# VM INSTANCES CONFIGURATION
# =========================================

variable "vm_instances" {
  description = "Map of VM instances to create"
  type = map(object({
    name               = optional(string)       # Custom VM name (defaults to key if not provided)
    zone               = string                 # GCP zone (e.g., "us-central1-a")
    machine_type       = optional(string, "e2-medium")  # Machine type
    boot_disk_size     = optional(number, 20)  # Boot disk size in GB
    boot_disk_type     = optional(string, "pd-standard")  # Boot disk type
    image_family       = optional(string, "ubuntu-2004-lts")  # OS image family
    image_project      = optional(string, "ubuntu-os-cloud")  # Image project
    
    # Network configuration
    network_name       = string                 # VPC network name
    subnet_name        = string                 # Subnet name
    external_ip        = optional(bool, false)  # Create external IP
    internal_ip        = optional(string)       # Static internal IP (optional)
    
    # Security and access
    network_tags       = optional(list(string), [])     # Network tags for firewall rules
    service_account    = optional(string)               # Service account email
    scopes            = optional(list(string), ["cloud-platform"])  # OAuth scopes
    
    # SSH and metadata
    enable_ssh_access  = optional(bool, true)   # Enable SSH access
    ssh_keys          = optional(list(string), [])  # SSH public keys
    metadata          = optional(map(string), {})    # Custom metadata
    
    # Startup and configuration
    startup_script    = optional(string, "")    # Startup script
    
    # Additional disks
    additional_disks  = optional(list(object({
      name   = string
      size   = number
      type   = optional(string, "pd-standard")
      device_name = optional(string)
    })), [])
    
    # Labels
    labels = optional(map(string), {})
  }))
  default = {}
}

# =========================================
# FIREWALL RULES
# =========================================

variable "firewall_rules" {
  description = "Additional firewall rules for compute instances"
  type = map(object({
    description    = string
    direction      = optional(string, "INGRESS")
    priority       = optional(number, 1000)
    source_ranges  = optional(list(string), [])
    target_tags    = optional(list(string), [])
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
  }))
  default = {}
}

# =========================================
# LOAD BALANCER CONFIGURATION
# =========================================

variable "create_load_balancer" {
  description = "Create a load balancer for the instances"
  type        = bool
  default     = false
}

variable "load_balancer_config" {
  description = "Load balancer configuration"
  type = object({
    name                = optional(string, "compute-lb")
    health_check_path   = optional(string, "/")
    health_check_port   = optional(number, 80)
    backend_port        = optional(number, 80)
    session_affinity    = optional(string, "NONE")
    enable_cdn          = optional(bool, false)
  })
  default = {
    name                = "compute-lb"
    health_check_path   = "/"
    health_check_port   = 80
    backend_port        = 80
    session_affinity    = "NONE"
    enable_cdn          = false
  }
}
