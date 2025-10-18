# Infrastructure Outputs

# Individual outputs for GitHub Actions workflow
output "server_public_ip" {
  description = "Public IP address of the deployed server"
  value       = module.compute.server_public_ip
}

output "domain_name" {
  description = "Full domain name for the deployment"
  value       = var.domain_name
}

output "zone_name" {
  description = "Calculated DNS zone name"
  value       = local.zone_name
}

output "subdomain_prefix" {
  description = "Calculated subdomain prefix"
  value       = local.subdomain_prefix
}

output "ssh_connection_string" {
  description = "SSH connection string for the deploy user"
  value       = module.compute.ssh_connection_string
}

# Server Information
output "server_info" {
  description = "Information about the provisioned server"
  value = {
    id             = module.compute.server_id
    name           = module.compute.server_name
    public_ip      = module.compute.server_public_ip
    private_ip     = module.compute.server_private_ip
    datacenter     = module.compute.server_datacenter
    status         = module.compute.server_status
    ssh_connection = module.compute.ssh_connection_string
  }
}

# DNS Information
output "dns_info" {
  description = "DNS configuration information"
  value       = module.dns.dns_summary
  sensitive   = false
}

# Deployment Information
output "deployment_info" {
  description = "Information needed for application deployment"
  value = {
    server_ip     = module.compute.server_public_ip
    domain_name   = module.dns.full_domain
    ssh_user      = "deploy"
    ssh_key_path  = "~/.ssh/deploy_rsa"
    app_directory = "/home/deploy/app"
    docker_swarm  = var.enable_docker_swarm
    environment   = "production"
  }
  sensitive = false
}

# Network Information
output "network_info" {
  description = "Network and firewall configuration"
  value = {
    firewall_id = module.compute.firewall_id
    allowed_ports = {
      ssh      = 22
      http     = 80
      https    = 443
      api      = 4000
      frontend = 3000
    }
    docker_swarm = {
      enabled      = var.enable_docker_swarm
      manager_port = 2377
      worker_port  = 7946
      overlay_port = 4789
    }
  }
}

# Connection Commands
output "connection_commands" {
  description = "Useful commands for connecting to and managing the server"
  value = {
    ssh_command            = "ssh root@${module.compute.server_public_ip}"
    scp_upload_command     = "scp LOCAL_FILE root@${module.compute.server_public_ip}:/opt/app/"
    rsync_command          = "rsync -avz LOCAL_DIR/ root@${module.compute.server_public_ip}:/opt/app/"
    docker_context_command = "docker context create remote --docker host=ssh://root@${module.compute.server_public_ip}"
    traefik_logs          = "ssh root@${module.compute.server_public_ip} 'docker service logs traefik'"
    swarmpit_logs         = "ssh root@${module.compute.server_public_ip} 'docker service logs swarmpit_app'"
    dozzle_logs           = "ssh root@${module.compute.server_public_ip} 'docker service logs dozzle_dozzle'"
    check_all_services    = "ssh root@${module.compute.server_public_ip} 'docker service ls'"
  }
  sensitive = false
}

# Application URLs
output "application_urls" {
  description = "URLs where the application will be accessible"
  value = {
    primary_domain        = "https://${module.dns.full_domain}"
    admin_dashboard       = "https://${var.traefik_host}"
    swarmpit_management   = "https://${var.swarmpit_host}"
    dozzle_logs          = "https://${var.dozzle_host}"
    api_endpoint          = "https://${module.dns.full_domain}/api"
    health_check          = "https://${var.traefik_host}/ping"
    application_frontend  = "https://${module.dns.full_domain}"
    direct_ip_http    = "http://${module.compute.server_public_ip}"
    direct_ip_https   = "https://${module.compute.server_public_ip}"
  }
}

# Security Information
output "security_info" {
  description = "Security configuration"
  value = {
    firewall_enabled    = true
    ssl_enabled         = true
    traefik_auth        = true
    admin_protected     = true
    rate_limiting       = true
    security_headers    = true
    docker_network      = "traefik-public"
    application_network = "app-network"
  }
  sensitive = false
}

# Monitoring and Maintenance
output "monitoring_info" {
  description = "Monitoring and maintenance information"
  value = {
    log_locations = {
      application = "/home/deploy/app/logs"
      docker      = "/var/log/docker"
      system      = "/var/log"
    }
    backup_location  = "/home/deploy/app/backups"
    health_check_url = "https://${module.dns.full_domain}/health"
    environment_file = "/home/deploy/app/.env.production"
  }
}

# Infrastructure Status
output "infrastructure_status" {
  description = "Overall infrastructure deployment status"
  value = {
    server_ready        = module.compute.server_status == "running" ? true : false
    dns_configured      = module.dns.domain_name != "" ? true : false
    domain_name         = module.dns.full_domain
    admin_domain        = var.traefik_host
    swarmpit_domain     = var.swarmpit_host
    dozzle_domain       = var.dozzle_host
    deployment_ready    = true
    platform_ready      = "Ready for application deployment"
    terraform_workspace = terraform.workspace
    last_updated        = timestamp()
  }
}

# Quick Start Commands
output "quick_start" {
  description = "Quick start commands for deployment"
  value = {
    connect_ssh         = "ssh root@${module.compute.server_public_ip}"
    check_docker_swarm  = "ssh root@${module.compute.server_public_ip} 'docker node ls'"
    check_traefik       = "ssh root@${module.compute.server_public_ip} 'docker service ls | grep traefik'"
    check_swarmpit      = "ssh root@${module.compute.server_public_ip} 'docker service ls | grep swarmpit'"
    check_dozzle        = "ssh root@${module.compute.server_public_ip} 'docker service ls | grep dozzle'"
    view_traefik_logs   = "ssh root@${module.compute.server_public_ip} 'docker service logs traefik --tail 50'"
    view_swarmpit_logs  = "ssh root@${module.compute.server_public_ip} 'docker service logs swarmpit_app --tail 50'"
    view_dozzle_logs    = "ssh root@${module.compute.server_public_ip} 'docker service logs dozzle_dozzle --tail 50'"
    check_networks      = "ssh root@${module.compute.server_public_ip} 'docker network ls'"
    check_all_services  = "ssh root@${module.compute.server_public_ip} 'docker service ls'"
    deploy_app_stack    = "# Upload docker-compose.yml to /opt/app/ then run: docker stack deploy -c docker-compose.yml myapp"
    admin_dashboard     = "https://${var.traefik_host}"
    swarmpit_management = "https://${var.swarmpit_host}"
    dozzle_logs_ui      = "https://${var.dozzle_host}"
    platform_url        = "https://${module.dns.full_domain}"
  }
}

# Resource IDs (for terraform state management)
output "resource_ids" {
  description = "Terraform resource IDs for state management"
  value = {
    server_id     = module.compute.server_id
    firewall_id   = module.compute.firewall_id
    dns_record_id = module.dns.primary_a_record_id
    ssh_key_id    = module.compute.ssh_key_id
  }
  sensitive = false
}

# Calculated DNS Records (for verification)
output "calculated_dns_records" {
  description = "Automatically calculated DNS records"
  value = {
    main_domain       = var.domain_name
    zone_name         = local.zone_name
    subdomain_prefix  = local.subdomain_prefix
    traefik_host      = var.traefik_host
    swarmpit_host     = var.swarmpit_host
    dozzle_host       = var.dozzle_host
    calculated_cnames = local.calculated_cname_records
    additional_cnames = var.additional_cname_records
    all_cname_records = local.all_cname_records
  }
  sensitive = false
}
