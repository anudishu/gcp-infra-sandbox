# Network Module

This module creates and manages GCP networking resources including VPC, subnets, firewall rules, Cloud NAT, and Identity Aware Proxy (IAP).

## Resources Created

- **VPC Network**: Main virtual private cloud
- **Subnets**: Regional subnets with optional secondary ranges
- **Cloud NAT**: Outbound internet access for private instances
- **Firewall Rules**: Network security rules
- **Custom Routes**: Custom routing configuration
- **IAP**: Identity Aware Proxy for secure application access

## Usage

```hcl
module "network" {
  source = "./modules/network"

  project_id   = "my-gcp-project"
  network_name = "main-vpc"

  subnets = {
    "web-subnet" = {
      ip_cidr_range            = "10.0.1.0/24"
      region                   = "us-central1"
      description              = "Subnet for web servers"
      private_ip_google_access = true
    }
    "app-subnet" = {
      ip_cidr_range            = "10.0.2.0/24"
      region                   = "us-central1"
      description              = "Subnet for application servers"
      private_ip_google_access = true
    }
  }

  firewall_rules = {
    "allow-web-traffic" = {
      description    = "Allow HTTP and HTTPS traffic"
      direction      = "INGRESS"
      priority       = 1000
      source_ranges  = ["0.0.0.0/0"]
      target_tags    = ["web-server"]
      allow = [{
        protocol = "tcp"
        ports    = ["80", "443"]
      }]
    }
  }

  enable_nat    = true
  nat_regions   = ["us-central1"]
  enable_iap    = true
  iap_support_email = "admin@company.com"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP project ID | `string` | n/a | yes |
| network_name | Name of the VPC network | `string` | `"main-vpc"` | no |
| subnets | Map of subnets to create | `map(object)` | `{}` | no |
| firewall_rules | Map of firewall rules | `map(object)` | `{}` | no |
| enable_nat | Enable Cloud NAT | `bool` | `true` | no |
| enable_iap | Enable Identity Aware Proxy | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | VPC network ID |
| network_name | VPC network name |
| subnets | Map of subnet information |
| firewall_rules | Map of firewall rule information |
| nat_gateways | Map of Cloud NAT information |

## Examples

See the `examples/` directory for complete usage examples.
