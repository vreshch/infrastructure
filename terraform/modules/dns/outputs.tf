# DNS Module Outputs

output "domain_name" {
  description = "The domain name being managed"
  value       = var.domain_name
}

output "full_domain" {
  description = "The full domain name including subdomain"
  value       = var.subdomain_prefix != "" ? "${var.subdomain_prefix}.${var.domain_name}" : var.domain_name
}

output "server_ip" {
  description = "The IP address the domain points to"
  value       = var.server_ip
}

output "primary_a_record_id" {
  description = "ID of the primary A record"
  value       = hetznerdns_record.main.id
}

output "www_cname_record_id" {
  description = "ID of the www CNAME record (if enabled)"
  value       = var.enable_www_redirect ? hetznerdns_record.www[0].id : null
}

output "additional_a_record_ids" {
  description = "IDs of additional A records"
  value       = { for k, v in hetznerdns_record.additional_a : k => v.id }
}

output "additional_cname_record_ids" {
  description = "IDs of additional CNAME records"
  value       = { for k, v in hetznerdns_record.additional_cname : k => v.id }
}

output "mx_record_ids" {
  description = "IDs of MX records (if enabled)"
  value       = { for k, v in hetznerdns_record.mx : k => v.id }
}

output "dns_summary" {
  description = "Summary of DNS configuration"
  value = {
    domain               = var.domain_name
    full_domain          = var.subdomain_prefix != "" ? "${var.subdomain_prefix}.${var.domain_name}" : var.domain_name
    primary_ip           = var.server_ip
    ttl                  = var.ttl
    www_redirect_enabled = var.enable_www_redirect
    mx_records_enabled   = var.enable_mx_records
    additional_records = {
      a_records     = length(var.additional_a_records)
      cname_records = length(var.additional_cname_records)
      mx_records    = length(var.mx_records)
    }
  }
}

output "zone_id" {
  description = "The ID of the DNS zone"
  value       = local.zone_id
}

output "zone_name" {
  description = "The name of the DNS zone"
  value       = var.existing_zone_id != null ? var.domain_name : hetznerdns_zone.main[0].name
}
