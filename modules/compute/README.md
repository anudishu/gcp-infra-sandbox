# Compute Module

This module creates and manages Google Cloud Compute Engine instances with flexible configuration options.

## Features

✅ **User-Friendly Configuration** - Simple variable structure for VM deployment  
✅ **VPC and Subnet Selection** - Choose existing network and subnet  
✅ **Custom VM Names** - Specify your own VM names or use auto-generated ones  
✅ **Multiple Instance Support** - Deploy multiple VMs with different configurations  
✅ **Additional Disks** - Attach extra persistent disks  
✅ **External IP Options** - Enable/disable external IP addresses  
✅ **SSH Access Control** - Built-in SSH key management  
✅ **Service Account Integration** - Assign service accounts to VMs  
✅ **Firewall Rules** - Create custom firewall rules  
✅ **Load Balancer Support** - Optional HTTP load balancer  
✅ **Startup Scripts** - Custom startup script execution  

## Usage

### Basic VM Configuration

```hcl
module "compute" {
  source = "./modules/compute"

  project_id = var.project_id

  vm_instances = {
    web-server = {
      name           = "my-web-server"
      zone           = "us-central1-a"
      machine_type   = "e2-medium"
      network_name   = "my-vpc-network"
      subnet_name    = "web-subnet"
      external_ip    = true
      network_tags   = ["web-server", "http-server"]
    }

    app-server = {
      name           = "my-app-server"
      zone           = "us-central1-b"
      machine_type   = "e2-standard-2"
      network_name   = "my-vpc-network"
      subnet_name    = "app-subnet"
      external_ip    = false
      network_tags   = ["app-server"]
    }
  }
}
```

### Advanced Configuration with Additional Features

```hcl
module "compute" {
  source = "./modules/compute"

  project_id = var.project_id

  vm_instances = {
    database-server = {
      name               = "prod-database"
      zone               = "us-central1-a"
      machine_type       = "n2-standard-4"
      boot_disk_size     = 50
      boot_disk_type     = "pd-ssd"
      image_family       = "ubuntu-2004-lts"
      network_name       = "production-vpc"
      subnet_name        = "database-subnet"
      internal_ip        = "10.0.1.10"
      external_ip        = false
      
      service_account    = "database-sa@project.iam.gserviceaccount.com"
      scopes            = ["cloud-platform"]
      
      network_tags      = ["database-server", "internal-only"]
      
      ssh_keys = [
        "user:ssh-rsa AAAAB3NzaC1yc2E... user@example.com"
      ]
      
      startup_script = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y postgresql
        systemctl enable postgresql
        systemctl start postgresql
      EOF
      
      additional_disks = [
        {
          name = "data-disk"
          size = 100
          type = "pd-ssd"
        }
      ]
      
      metadata = {
        environment = "production"
        backup      = "enabled"
      }
      
      labels = {
        application = "database"
        tier       = "data"
      }
    }
  }

  # Custom firewall rules
  firewall_rules = {
    "allow-database-access" = {
      description   = "Allow database access from app servers"
      source_ranges = ["10.0.2.0/24"]
      target_tags   = ["database-server"]
      allow = [{
        protocol = "tcp"
        ports    = ["5432"]
      }]
    }
  }

  # Optional load balancer
  create_load_balancer = true
  load_balancer_config = {
    name                = "app-load-balancer"
    health_check_path   = "/health"
    health_check_port   = 8080
    backend_port        = 8080
  }
}
```

## Variables

### Required Variables

| Variable | Description | Type |
|----------|-------------|------|
| `project_id` | GCP project ID | `string` |
| `vm_instances` | Map of VM configurations | `map(object)` |

### VM Instance Configuration

Each VM in `vm_instances` supports these options:

| Option | Description | Type | Default |
|--------|-------------|------|---------|
| `name` | Custom VM name | `string` | Uses map key |
| `zone` | GCP zone | `string` | **Required** |
| `machine_type` | Machine type | `string` | `e2-medium` |
| `boot_disk_size` | Boot disk size (GB) | `number` | `20` |
| `boot_disk_type` | Boot disk type | `string` | `pd-standard` |
| `image_family` | OS image family | `string` | `ubuntu-2004-lts` |
| `image_project` | Image project | `string` | `ubuntu-os-cloud` |
| `network_name` | VPC network name | `string` | **Required** |
| `subnet_name` | Subnet name | `string` | **Required** |
| `external_ip` | Create external IP | `bool` | `false` |
| `internal_ip` | Static internal IP | `string` | Auto-assigned |
| `network_tags` | Network tags | `list(string)` | `[]` |
| `service_account` | Service account email | `string` | None |
| `scopes` | OAuth scopes | `list(string)` | `["cloud-platform"]` |
| `enable_ssh_access` | Enable SSH | `bool` | `true` |
| `ssh_keys` | SSH public keys | `list(string)` | `[]` |
| `metadata` | Custom metadata | `map(string)` | `{}` |
| `startup_script` | Startup script | `string` | `""` |
| `additional_disks` | Extra disks | `list(object)` | `[]` |
| `labels` | Resource labels | `map(string)` | `{}` |

## Outputs

### Main Outputs

| Output | Description |
|--------|-------------|
| `vm_instances` | Complete VM instance information |
| `vm_names` | List of VM names |
| `vm_internal_ips` | Map of internal IP addresses |
| `vm_external_ips` | Map of external IP addresses |
| `ssh_commands` | SSH connection commands |
| `summary` | Resource summary |

### SSH Connection

The module outputs ready-to-use SSH commands:

```bash
# Connect using internal IP
gcloud compute ssh my-vm --zone=us-central1-a --internal-ip

# Connect using external IP (if available)
gcloud compute ssh my-vm --zone=us-central1-a
```

## Examples

### Web Server with Load Balancer

```hcl
vm_instances = {
  web-1 = {
    zone         = "us-central1-a"
    machine_type = "e2-medium"
    network_name = "web-vpc"
    subnet_name  = "public-subnet"
    external_ip  = true
    network_tags = ["web-server", "http-server"]
    
    startup_script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      systemctl enable nginx
      systemctl start nginx
    EOF
  }
  
  web-2 = {
    zone         = "us-central1-b"
    machine_type = "e2-medium"
    network_name = "web-vpc"
    subnet_name  = "public-subnet"
    external_ip  = true
    network_tags = ["web-server", "http-server"]
    
    startup_script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y nginx
      systemctl enable nginx
      systemctl start nginx
    EOF
  }
}

create_load_balancer = true
```

### Database Server with Additional Storage

```hcl
vm_instances = {
  database = {
    name           = "prod-db-01"
    zone           = "us-central1-a"
    machine_type   = "n2-standard-4"
    boot_disk_size = 50
    boot_disk_type = "pd-ssd"
    network_name   = "private-vpc"
    subnet_name    = "database-subnet"
    internal_ip    = "10.1.1.10"
    external_ip    = false
    
    additional_disks = [
      {
        name = "database-data"
        size = 500
        type = "pd-ssd"
      },
      {
        name = "database-logs"
        size = 100
        type = "pd-standard"
      }
    ]
    
    network_tags = ["database", "no-external-ip"]
  }
}
```

## Prerequisites

- Existing VPC network and subnets
- Proper IAM permissions for Compute Engine
- Firewall rules for desired access (or use module's firewall_rules)

## Common Machine Types

| Type | vCPUs | Memory | Use Case |
|------|-------|--------|----------|
| `e2-micro` | 0.25-2 | 1 GB | Testing, light workloads |
| `e2-small` | 0.5-2 | 2 GB | Development |
| `e2-medium` | 1-2 | 4 GB | Web servers |
| `e2-standard-2` | 2 | 8 GB | Application servers |
| `e2-standard-4` | 4 | 16 GB | Database servers |
| `n2-standard-4` | 4 | 16 GB | High-performance workloads |

## Security Best Practices

1. **Use Internal IPs**: Set `external_ip = false` for internal services
2. **Network Tags**: Use specific tags for firewall targeting
3. **Service Accounts**: Assign minimal required permissions
4. **SSH Keys**: Use SSH keys instead of passwords
5. **Startup Scripts**: Avoid sensitive data in startup scripts
6. **Labels**: Tag resources for better organization and billing

## Troubleshooting

### Common Issues

1. **Network/Subnet Not Found**: Ensure VPC and subnet exist in the specified region
2. **Permission Denied**: Verify Compute Engine API is enabled and IAM permissions
3. **Zone Mismatch**: Subnet region must match VM zone region
4. **Quota Exceeded**: Check Compute Engine quotas in your project

### Debug Commands

```bash
# Check VM status
gcloud compute instances list

# View VM details
gcloud compute instances describe VM_NAME --zone=ZONE

# Check firewall rules
gcloud compute firewall-rules list

# Test connectivity
gcloud compute ssh VM_NAME --zone=ZONE --command="echo 'Connected!'"
```
