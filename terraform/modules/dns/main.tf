# Hetzner DNS Configuration

terraform {
  required_providers {
    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "~> 2.2"
    }
  }
}

# Configure the Hetzner DNS Provider
provider "hetznerdns" {
  apitoken = var.hetzner_dns_token
}

# Create the DNS zone only if existing_zone_id is not provided
resource "hetznerdns_zone" "main" {
  count = var.existing_zone_id == null ? 1 : 0
  name  = var.domain_name
  ttl   = var.ttl
}

# Local value to determine which zone ID to use
locals {
  zone_id = var.existing_zone_id != null ? var.existing_zone_id : hetznerdns_zone.main[0].id
}

# Primary A record for the domain/subdomain
resource "hetznerdns_record" "main" {
  zone_id = local.zone_id
  name    = var.subdomain_prefix != "" ? var.subdomain_prefix : "@"
  value   = var.server_ip
  type    = "A"
  ttl     = var.ttl
}

# WWW CNAME record (if enabled)
resource "hetznerdns_record" "www" {
  count   = var.enable_www_redirect ? 1 : 0
  zone_id = local.zone_id
  name    = var.subdomain_prefix != "" && var.subdomain_prefix != "@" ? "www.${var.subdomain_prefix}" : "www"
  value   = var.subdomain_prefix != "" ? "${var.subdomain_prefix}.${var.domain_name}." : "${var.domain_name}."
  type    = "CNAME"
  ttl     = var.ttl
}

# Additional A records
resource "hetznerdns_record" "additional_a" {
  for_each = { for record in var.additional_a_records : record.name => record }
  zone_id  = local.zone_id
  name     = each.value.name
  value    = each.value.ip
  type     = "A"
  ttl      = var.ttl
}

# Additional CNAME records
resource "hetznerdns_record" "additional_cname" {
  for_each = { for record in var.additional_cname_records : record.name => record }
  zone_id  = local.zone_id
  name     = each.value.name
  value    = each.value.target
  type     = "CNAME"
  ttl      = var.ttl
}

# MX records (if enabled)
resource "hetznerdns_record" "mx" {
  for_each = var.enable_mx_records ? { for idx, record in var.mx_records : idx => record } : {}
  zone_id  = local.zone_id
  name     = "@"
  value    = "${each.value.priority} ${each.value.server}"
  type     = "MX"
  ttl      = var.ttl
}
