# =============================================================================
# 🌐 MCPXHUB.IO TERRAFORM CONFIGURATION TEMPLATE
# =============================================================================
# 
# This is an example configuration file for deploying mcpxhub.io infrastructure.
# Copy this file to create environment-specific configurations:
#
# For Development:   cp terraform.example.tfvars terraform.dev.tfvars
# For Production:    cp terraform.example.tfvars terraform.prod.tfvars
# For Staging:       cp terraform.example.tfvars terraform.staging.tfvars
#
# After copying, fill in your actual values and secure the file:
#   chmod 600 terraform.{env}.tfvars
#   echo "*.tfvars" >> .gitignore  # Ensure sensitive files are not committed
#
# =============================================================================

# =============================================================================
# 🌐 DOMAIN AND DNS CONFIGURATION
# =============================================================================

# Primary domain for your deployment
# Examples:
#   - Production: "mcpxhub.io"
#   - Development: "dev.mcpxhub.io" 
#   - Staging: "staging.mcpxhub.io"
domain_name = "your-domain.com"

# Hetzner DNS Zone ID
# How to find: 
#   1. Go to https://dns.hetzner.com/
#   2. Navigate to: DNS Console > Zones > Select your zone
#   3. Copy the Zone ID from the URL or zone details
hetzner_dns_zone_id = "YOUR_HETZNER_DNS_ZONE_ID"

# Hetzner DNS API Token
# How to generate:
#   1. Go to https://dns.hetzner.com/settings/api-token
#   2. Click "Generate API Token"
#   3. Give it a descriptive name (e.g., "mcpxhub-terraform")
#   4. Set permissions: Zone:Read, Zone:Edit, Record:Read, Record:Write
#   5. Copy the generated token
hetzner_dns_token = "YOUR_HETZNER_DNS_API_TOKEN"

# =============================================================================
# ☁️ HETZNER CLOUD CONFIGURATION
# =============================================================================

# Hetzner Cloud API Token
# How to generate:
#   1. Go to https://console.hetzner.cloud/
#   2. Navigate to: Security > API Tokens
#   3. Click "Generate API Token"
#   4. Give it a descriptive name (e.g., "mcpxhub-terraform")
#   5. Set permissions: Read & Write for all resources
#   6. Copy the generated token
hetzner_token = "YOUR_HETZNER_CLOUD_API_TOKEN"

# Server configuration
server_name = "mcpxhub-server"        # Server hostname in Hetzner Cloud
server_type = "cx22"                  # Server type: cx11 (€4.15), cx22 (€8.21), cx32 (€16.59)
location = "nbg1"                     # Datacenter: nbg1 (Nuremberg), fsn1 (Falkenstein), hel1 (Helsinki), ash (Virginia)
environment = "development"           # Environment label: development, staging, production

# =============================================================================
# 🔐 SSH KEY CONFIGURATION
# =============================================================================

# SSH Public Key for server access
# How to generate:
#   1. Generate a new SSH key pair:
#      ssh-keygen -t rsa -b 4096 -C "your-email@domain.com" -f ~/.ssh/mcpxhub_rsa
#   2. Copy the PUBLIC key content:
#      cat ~/.ssh/mcpxhub_rsa.pub
#   3. Paste the entire public key content below (starts with ssh-rsa)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAA... your-email@domain.com"

# SSH Private Key for automated deployment
# Security Note: This will be stored in Terraform state - use a dedicated deployment key
# How to get:
#   1. Copy the PRIVATE key content:
#      cat ~/.ssh/mcpxhub_rsa
#   2. Paste the entire private key content below (including BEGIN/END lines)
ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
YOUR_PRIVATE_KEY_CONTENT_HERE
-----END OPENSSH PRIVATE KEY-----
EOT

# =============================================================================
# 🛡️ ADMIN AUTHENTICATION CONFIGURATION
# =============================================================================

# Admin password hash for Traefik dashboard access
# How to generate:
#   1. Install apache2-utils: sudo apt install apache2-utils
#   2. Generate hash: htpasswd -nbB admin your_secure_password
#   3. Extract the hash part (everything after "admin:")
#   4. Base64 encode it: echo "HASH_PART" | base64 -w0
# Example command: htpasswd -nbB admin mypassword | cut -d: -f2 | base64 -w0
admin_password_hash = "YOUR_BASE64_ENCODED_PASSWORD_HASH"

# Service hostnames (will be created as subdomains)
traefik_host = "traefik.your-domain.com"    # Admin dashboard URL
swarmpit_host = "swarmpit.your-domain.com"  # Docker Swarm management URL
dozzle_host = "logs.your-domain.com"        # Container logs URL

# Email for Let's Encrypt SSL certificates
# Must be a valid email address for SSL certificate notifications
traefik_acme_email = "admin@your-domain.com"

# =============================================================================
# 🐳 DOCKER SWARM CONFIGURATION
# =============================================================================

# Enable Docker Swarm for container orchestration
# Set to true for production deployments, false for simple Docker setups
enable_docker_swarm = true

# =============================================================================
# 🌐 ADDITIONAL DNS RECORDS (OPTIONAL)
# =============================================================================

# Additional CNAME records for custom services
# Example:
# additional_cname_records = [
#   {
#     name   = "api"
#     target = "your-domain.com."
#   },
#   {
#     name   = "cdn"
#     target = "your-domain.com."
#   }
# ]
additional_cname_records = []

# Additional A records for custom IPs
# Example:
# additional_a_records = [
#   {
#     name  = "test"
#     value = "192.168.1.100"
#   }
# ]
additional_a_records = []

# =============================================================================
# 📝 DEPLOYMENT INSTRUCTIONS
# =============================================================================
#
# 1. 🔧 SETUP:
#    - Copy this file: cp terraform.example.tfvars terraform.prod.tfvars
#    - Fill in all the variables above with your actual values
#    - Secure the file: chmod 600 terraform.prod.tfvars
#
# 2. 🚀 DEPLOY:
#    - Initialize: terraform init
#    - Plan: terraform plan -var-file="terraform.prod.tfvars"
#    - Apply: terraform apply -var-file="terraform.prod.tfvars"
#
# 3. 🔍 VERIFY:
#    - Check outputs: terraform output
#    - Test SSH: ssh root@$(terraform output -raw server_public_ip)
#    - Check services: terraform output quick_start
#
# 4. 📊 MONITORING:
#    - Traefik Dashboard: https://traefik.your-domain.com
#    - Swarmpit Management: https://swarmpit.your-domain.com
#    - Container Logs: https://logs.your-domain.com
#
# 5. 💰 ESTIMATED COSTS:
#    - CX22 Server: €8.21/month
#    - DNS Zone: €1.00/month
#    - Total: ~€9.21/month
#
# 6. 🔒 SECURITY CHECKLIST:
#    - [ ] Use strong, unique passwords
#    - [ ] Secure SSH keys (dedicated deployment keys)
#    - [ ] Enable MFA on Hetzner accounts
#    - [ ] Regular security updates
#    - [ ] Monitor access logs
#    - [ ] Backup configuration and data
#
# 7. 🚨 TROUBLESHOOTING:
#    - DNS propagation can take up to 24 hours
#    - SSL certificates generate automatically (5-10 minutes)
#    - Check Terraform logs for detailed error messages
#    - Verify API tokens have correct permissions
#
# =============================================================================
# 🆘 SUPPORT AND DOCUMENTATION
# =============================================================================
#
# - Project Documentation: docs/
# - Terraform Docs: https://registry.terraform.io/providers/hetznercloud/hcloud
# - Hetzner Cloud Docs: https://docs.hetzner.com/cloud/
# - Hetzner DNS Docs: https://dns.hetzner.com/api-docs
# - Issues: https://github.com/vreshch/mcpxhub.io/issues
#
# =============================================================================
