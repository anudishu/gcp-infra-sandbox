# =========================================
# SHIVANI'S GCP INFRASTRUCTURE CONFIGURATION
# =========================================

# Project Configuration
project_id      = "probable-cove-474504-p0"
organization_id = ""  # Optional
folder_id      = ""   # Optional

# Basic Configuration
environment    = "dev"
project_name   = "shivani-infrastructure"
default_region = "us-central1"
default_zone   = "us-central1-a"

# Labels
default_labels = {
  managed-by   = "terraform"
  environment  = "dev"
  team         = "infrastructure"
  owner        = "shivani"
}

# Feature Flags
create_network = true
create_storage = true
create_iam     = false  # DISABLED - No permissions to create custom roles
create_compute = true

# Network Configuration
network_config = {
  network_name = "main-vpc"
  
  subnets = {
    "web-subnet" = {
      ip_cidr_range            = "10.0.1.0/24"
      region                   = "us-central1"
      description              = "Subnet for web tier"
      private_ip_google_access = true
    }
    
    "app-subnet" = {
      ip_cidr_range            = "10.0.2.0/24"
      region                   = "us-central1"
      description              = "Subnet for application tier"
      private_ip_google_access = true
    }
  }
  
  enable_nat        = false
  nat_regions       = ["us-central1"]
  enable_iap        = false
  iap_support_email = null
}

# Storage Configuration
storage_config = {
  buckets = {
    "app-data-bucket" = {
      location               = "US"
      storage_class         = "STANDARD"
      versioning_enabled    = true
      force_destroy         = true  # Set to true for dev environment
      labels = {
        purpose = "application-data"
      }
    }
    
    "backup-bucket" = {
      location      = "US"
      storage_class = "COLDLINE"
      force_destroy = true
      labels = {
        purpose = "backups"
      }
    }
  }
}

# IAM Configuration - DISABLED (No permissions to create custom roles)
# iam_config = {
#   service_accounts = {
#     "app-sa" = {
#       display_name = "Application Service Account"
#       description  = "Service account for application workloads"
#     }
#     
#     "abcsa" = {
#       display_name = "ABC Service Account"
#       description  = "Service account with compute admin privileges"
#     }
#   }
#   
#   project_iam_bindings = {
#     "roles/compute.admin" = {
#       members = [
#         "serviceAccount:shivani-dev-abcsa@probable-cove-474504-p0.iam.gserviceaccount.com"
#       ]
#     }
#     "roles/storage.objectAdmin" = {
#       members = [
#         "serviceAccount:shivani-dev-app-sa@probable-cove-474504-p0.iam.gserviceaccount.com"
#       ]
#     }
#   }
# }

# =========================================
# COMPUTE CONFIGURATION
# =========================================

compute_config = {
  # VM instances configuration - just one web server for now
  vm_instances = {
    # Basic web server with external IP
    web-server = {
      name           = "shivani-web-server"           # Custom VM name
      zone           = "us-central1-a"                # GCP zone
      machine_type   = "e2-medium"                    # 1 vCPU, 4GB RAM
      boot_disk_size = 20                            # 20GB boot disk
      boot_disk_type = "pd-standard"                  # Boot disk type (pd-standard, pd-ssd, pd-balanced)
      
      # Operating System Image Selection
      image_family   = "rhel-10"                     # Red Hat Enterprise Linux 10
      image_project  = "rhel-cloud"                  # RHEL image project
      
      # Network configuration - using generated names from main.tf
      network_name   = "shivani-infrastructure-dev-main-vpc"
      subnet_name    = "shivani-infrastructure-dev-web-subnet"
      external_ip    = true                          # Internet access
      
      # Security tags for firewall rules
      #network_tags   = ["web-server", "http-server", "ssh-allowed"]
      
      # Service account - DISABLED (IAM module disabled)
      # service_account = "shivani-dev-app-sa@probable-cove-474504-p0.iam.gserviceaccount.com"
      
      # Enable SSH access
      enable_ssh_access = true
      
      # Basic startup script to install nginx (RHEL compatible)
      startup_script = <<-EOF
        #!/bin/bash
        # Update system and install nginx
        dnf update -y
        dnf install -y nginx
        systemctl enable nginx
        systemctl start nginx
        
        # Create custom welcome page
        echo "<h1>Welcome to Shivani's Web Server</h1>" > /usr/share/nginx/html/index.html
        echo "<p>Server: $(hostname)</p>" >> /usr/share/nginx/html/index.html
        echo "<p>Date: $(date)</p>" >> /usr/share/nginx/html/index.html
        echo "<p>OS: Red Hat Enterprise Linux 10</p>" >> /usr/share/nginx/html/index.html
        
        # Configure firewall for HTTP/HTTPS
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
      EOF
      
      # Labels for organization
      labels = {
        environment = "dev"
        application = "web-server"
        owner      = "shivani"
      }
    }
  }

  # Empty configurations (required by module but not used)
  firewall_rules = {}
  create_load_balancer = false
  load_balancer_config = {}
}