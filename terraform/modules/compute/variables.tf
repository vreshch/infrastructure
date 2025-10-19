variable "server_name" {
  description = "Name of the Hetzner server"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.server_name))
    error_message = "Server name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "server_type" {
  description = "Hetzner server type for MCP catalog platform"
  type        = string
  default     = "cx22"
  validation {
    condition = contains([
      "cx11", "cx21", "cx22", "cx23", "cx31", "cx32", "cx33", "cx41", "cx42", "cx43", "cx51", "cx52", "cx53"
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

variable "enable_docker_swarm" {
  description = "Whether to initialize Docker Swarm for MCP platform deployment"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (used for tagging)"
  type        = string
  default     = "production"
}

# Service Configuration Variables
variable "admin_password_hash" {
  description = "Admin password hash for services (bcrypt format from htpasswd)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "traefik_host" {
  description = "Hostname for Traefik admin dashboard access"
  type        = string
  default     = "admin.example.com"
}

variable "traefik_acme_email" {
  description = "Email address for Let's Encrypt ACME certificates"
  type        = string
  default     = "admin@example.com"
}

variable "swarmpit_host" {
  description = "Hostname for Swarmpit web interface"
  type        = string
  default     = "swarmpit.example.com"
}

variable "dozzle_host" {
  description = "Hostname for Dozzle logging interface"
  type        = string
  default     = "dozzle.example.com"
}
