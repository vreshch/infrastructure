module "compute" {
  source = "./modules/compute"

  server_name         = var.server_name
  server_type         = var.server_type
  location            = var.location
  ssh_public_key      = var.ssh_public_key
  ssh_private_key     = var.ssh_private_key
  enable_docker_swarm = var.enable_docker_swarm # true by default
  environment         = var.environment         # production by default

  # Service configuration variables
  admin_password_hash = var.admin_password_hash
  traefik_host        = var.traefik_host
  swarmpit_host       = var.swarmpit_host
  dozzle_host         = var.dozzle_host
  traefik_acme_email  = var.traefik_acme_email
}

module "dns" {
  source              = "./modules/dns"
  existing_zone_id    = var.hetzner_dns_zone_id # Use variable instead of hardcoded value
  server_ip           = module.compute.server_public_ip
  hetzner_dns_token   = var.hetzner_dns_token
  domain_name         = local.zone_name         # Extracted from domain_name (e.g., "example.com" from "app.example.com")
  subdomain_prefix    = local.subdomain_prefix  # Calculated from domain_name (e.g., "app" for app.example.com, "@" for example.com)
  ttl                 = var.ttl                 # Default TTL is 60 seconds
  enable_www_redirect = var.enable_www_redirect # true by default

  # Use calculated CNAME records that automatically create records based on traefik_host
  additional_cname_records = local.all_cname_records
  additional_a_records     = var.additional_a_records
}
