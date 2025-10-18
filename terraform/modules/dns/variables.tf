# DNS Module Variables

variable "hetzner_dns_token" {
  description = "Hetzner DNS API token"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name to manage"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "server_ip" {
  description = "IP address of the server to point DNS records to"
  type        = string
  validation {
    condition     = can(cidrhost("${var.server_ip}/32", 0))
    error_message = "Server IP must be a valid IPv4 address."
  }
}

variable "subdomain_prefix" {
  description = "Subdomain prefix (e.g., 'status' for status.domain.com, '@' for apex domain)"
  type        = string
  default     = ""
  validation {
    condition     = var.subdomain_prefix == "" || var.subdomain_prefix == "@" || can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.subdomain_prefix))
    error_message = "Subdomain prefix must be empty, '@' for apex domain, or a valid subdomain format."
  }
}

variable "ttl" {
  description = "TTL for DNS records in seconds"
  type        = number
  default     = 60
  validation {
    condition     = var.ttl >= 60 && var.ttl <= 86400
    error_message = "TTL must be between 60 and 86400 seconds."
  }
}

variable "enable_www_redirect" {
  description = "Enable www subdomain redirect"
  type        = bool
  default     = true
}

variable "enable_mx_records" {
  description = "Enable MX records for email"
  type        = bool
  default     = false
}

variable "mx_records" {
  description = "List of MX records"
  type = list(object({
    priority = number
    server   = string
  }))
  default = []
}

variable "additional_a_records" {
  description = "Additional A records to create"
  type = list(object({
    name = string
    ip   = string
  }))
  default = []
}

variable "additional_cname_records" {
  description = "Additional CNAME records to create"
  type = list(object({
    name   = string
    target = string
  }))
  default = []
}

variable "existing_zone_id" {
  description = "ID of existing DNS zone to use (if provided, no new zone will be created)"
  type        = string
  default     = null
}
