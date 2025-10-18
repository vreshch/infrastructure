# Hetzner Cloud Configuration
variable "hetzner_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

# Hetzner DNS Configuration
variable "hetzner_dns_token" {
  description = "Hetzner DNS API token"
  type        = string
  sensitive   = true
}

variable "hetzner_dns_zone_id" {
  description = "Hetzner DNS Zone ID for the domain"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.hetzner_dns_zone_id))
    error_message = "Hetzner DNS Zone ID must contain only alphanumeric characters."
  }
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key content for server access"
  type        = string
  validation {
    condition     = can(regex("^ssh-", var.ssh_public_key))
    error_message = "SSH public key must start with ssh- (ssh-rsa, ssh-ed25519, etc.)."
  }
}

variable "ssh_private_key" {
  description = "SSH private key content for server access (PEM format)"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("-----BEGIN.*PRIVATE KEY-----", var.ssh_private_key))
    error_message = "SSH private key must be in PEM format."
  }
}

# Server Configuration
variable "server_name" {
  description = "Name for the Hetzner server"
  type        = string
  default     = "docker-swarm-server"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.server_name))
    error_message = "Server name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cx22"
  validation {
    condition = contains([
      "cx11", "cx21", "cx22", "cx31", "cx32", "cx41", "cx42", "cx51", "cx52"
    ], var.server_type)
    error_message = "Server type must be a valid Hetzner server type."
  }
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1"
  validation {
    condition = contains([
      "nbg1", "fsn1", "hel1", "ash", "hil"
    ], var.location)
    error_message = "Location must be a valid Hetzner datacenter location."
  }
}

# Docker Configuration
variable "enable_docker_swarm" {
  description = "Whether to initialize Docker Swarm on the server"
  type        = bool
  default     = true
}

# DNS Configuration
variable "domain_name" {
  description = "Primary domain name for your infrastructure deployment"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid FQDN."
  }
}

# Service Configuration Variables
variable "admin_password_hash" {
  description = "Generic admin password hash for services (base64 encoded htpasswd format)"
  type        = string
  sensitive   = true
  default     = ""
  validation {
    condition     = var.admin_password_hash == "" || can(base64decode(var.admin_password_hash))
    error_message = "Admin password hash must be a valid base64 encoded string or empty string."
  }
}

variable "traefik_host" {
  description = "Hostname for Traefik dashboard access (e.g., admin.yourdomain.com)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.traefik_host))
    error_message = "Traefik host must be a valid FQDN."
  }
}

variable "traefik_acme_email" {
  description = "Email address for Let's Encrypt ACME certificates (e.g., admin@yourdomain.com)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.traefik_acme_email))
    error_message = "ACME email must be a valid email address."
  }
}

variable "swarmpit_host" {
  description = "Hostname for Swarmpit web interface (e.g., swarmpit.yourdomain.com)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.swarmpit_host))
    error_message = "Swarmpit host must be a valid FQDN."
  }
}

variable "dozzle_host" {
  description = "Hostname for Dozzle logging interface (e.g., logs.yourdomain.com)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.dozzle_host))
    error_message = "Dozzle host must be a valid FQDN."
  }
}

# DNS CNAME Records Configuration
variable "additional_cname_records" {
  description = "List of additional CNAME records to create (beyond auto-calculated ones)"
  type = list(object({
    name   = string
    target = string
  }))
  default = []
  validation {
    condition = alltrue([
      for record in var.additional_cname_records : can(regex("^[a-z0-9.-]+$", record.name))
    ])
    error_message = "CNAME record names must contain only lowercase letters, numbers, dots, and hyphens."
  }
}

# Additional A Records Configuration
variable "additional_a_records" {
  description = "List of additional A records to create"
  type = list(object({
    name = string
    ip   = string
  }))
  default = []
  validation {
    condition = alltrue([
      for record in var.additional_a_records : can(regex("^[a-z0-9.-]+$", record.name))
    ])
    error_message = "A record names must contain only lowercase letters, numbers, dots, and hyphens."
  }
}

# Automatically calculated DNS values
locals {
  # Extract domain parts
  domain_parts = split(".", var.domain_name)

  # Calculate zone name (last two parts of domain)
  zone_name = length(local.domain_parts) > 2 ? join(".", slice(local.domain_parts, length(local.domain_parts) - 2, length(local.domain_parts))) : var.domain_name

  # Calculate subdomain prefix
  subdomain_prefix = length(local.domain_parts) > 2 ? join(".", slice(local.domain_parts, 0, length(local.domain_parts) - 2)) : "@"

  # Calculate CNAME records based on service hosts and domain_name
  calculated_cname_records = concat(
    # Traefik CNAME record
    var.traefik_host != "" && var.traefik_host != var.domain_name ? [
      {
        # Extract subdomain from traefik_host (e.g., "traefik-dev" from "traefik-dev.example.com")
        name   = replace(var.traefik_host, ".${local.zone_name}", "")
        target = "${var.domain_name}."
      }
    ] : [],
    # Swarmpit CNAME record
    var.swarmpit_host != "" && var.swarmpit_host != var.domain_name ? [
      {
        # Extract subdomain from swarmpit_host (e.g., "swarmpit-dev" from "swarmpit-dev.example.com")
        name   = replace(var.swarmpit_host, ".${local.zone_name}", "")
        target = "${var.domain_name}."
      }
    ] : [],
    # Dozzle CNAME record
    var.dozzle_host != "" && var.dozzle_host != var.domain_name ? [
      {
        # Extract subdomain from dozzle_host (e.g., "dozzle-dev" from "dozzle-dev.example.com")
        name   = replace(var.dozzle_host, ".${local.zone_name}", "")
        target = "${var.domain_name}."
      }
    ] : []
  )

  # Combine calculated and additional CNAME records
  all_cname_records = concat(local.calculated_cname_records, var.additional_cname_records)
}

variable "ttl" {
  description = "TTL for DNS records in seconds (alias for dns_ttl for backward compatibility)"
  type        = number
  default     = 300
  validation {
    condition     = var.ttl >= 60 && var.ttl <= 86400
    error_message = "TTL must be between 60 and 86400 seconds."
  }
}

variable "dns_ttl" {
  description = "TTL for DNS records in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.dns_ttl >= 60 && var.dns_ttl <= 86400
    error_message = "DNS TTL must be between 60 and 86400 seconds."
  }
}

variable "enable_www_redirect" {
  description = "Whether to enable www to non-www redirect for the domain"
  type        = bool
  default     = true
}

variable "enable_caa_record" {
  description = "Whether to create a CAA record for SSL certificate authority"
  type        = bool
  default     = true
}

# Environment Configuration
variable "environment" {
  description = "Environment name (used for tagging and naming)"
  type        = string
  default     = "production"
  validation {
    condition = contains([
      "development", "staging", "production"
    ], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "project_name" {
  description = "Project name (used for tagging and resource naming)"
  type        = string
  default     = "infrastructure"
}
