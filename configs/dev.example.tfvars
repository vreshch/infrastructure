# =============================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# =============================================================================
# 
# This configuration is optimized for development and testing.
# - Smaller server size for cost savings
# - Development-specific naming conventions
# - Less strict security for easier debugging
#
# Copy this file: cp dev.example.tfvars dev.tfvars
# Then fill in your actual values.
#
# =============================================================================

# =============================================================================
# DOMAIN AND DNS CONFIGURATION
# =============================================================================

domain_name         = "dev.yourdomain.com"      # Development subdomain
hetzner_dns_zone_id = "YOUR_DNS_ZONE_ID"        # Same zone as production
hetzner_dns_token   = "YOUR_DNS_API_TOKEN"

# =============================================================================
# CLOUD CONFIGURATION
# =============================================================================

hetzner_token = "YOUR_CLOUD_API_TOKEN"

# Development server - Small and cost-effective
server_name = "dev-server"
server_type = "cx22"           # 4GB RAM, 2 vCPUs (~€8/month)
location    = "nbg1"           # Nuremberg datacenter
environment = "development"

# =============================================================================
# SSH CONFIGURATION
# =============================================================================

ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAA... dev@yourdomain.com"

ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
YOUR_DEV_PRIVATE_KEY
-----END OPENSSH PRIVATE KEY-----
EOT

# =============================================================================
# ADMIN AUTHENTICATION
# =============================================================================

# Use a simple password for development (still secure it!)
admin_password_hash = "YOUR_PASSWORD_HASH"

# Development service hostnames
traefik_host       = "admin.dev.yourdomain.com"
swarmpit_host      = "swarmpit.dev.yourdomain.com"
dozzle_host        = "logs.dev.yourdomain.com"
traefik_acme_email = "dev@yourdomain.com"

# =============================================================================
# DOCKER CONFIGURATION
# =============================================================================

enable_docker_swarm = true

# =============================================================================
# ADDITIONAL DNS (Optional)
# =============================================================================

additional_cname_records = []
additional_a_records     = []

# =============================================================================
# DEVELOPMENT NOTES
# =============================================================================
#
# Monthly Cost: ~€8 (CX22 server)
# 
# Features:
# - Automatic SSL certificates via Let's Encrypt
# - Docker Swarm for testing container orchestration
# - Full monitoring stack (Traefik, Swarmpit, Dozzle)
#
# Deployment:
#   cd terraform/
#   terraform workspace select dev || terraform workspace new dev
#   terraform plan -var-file="../configs/dev.tfvars"
#   terraform apply -var-file="../configs/dev.tfvars"
#
# Remember to destroy when not in use to save costs:
#   terraform destroy -var-file="../configs/dev.tfvars"
#
# =============================================================================
