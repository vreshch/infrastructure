# =============================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# =============================================================================
# 
# This configuration is optimized for production workloads.
# - Larger server size for better performance
# - Production-grade security settings
# - Backup and monitoring enabled
#
# ⚠️  IMPORTANT: Production deployment requires careful review!
#
# Copy this file: cp prod.example.tfvars prod.tfvars
# Then fill in your actual values.
#
# =============================================================================

# =============================================================================
# DOMAIN AND DNS CONFIGURATION
# =============================================================================

domain_name         = "yourdomain.com"          # Primary production domain
hetzner_dns_zone_id = "YOUR_DNS_ZONE_ID"
hetzner_dns_token   = "YOUR_DNS_API_TOKEN"

# =============================================================================
# CLOUD CONFIGURATION
# =============================================================================

hetzner_token = "YOUR_CLOUD_API_TOKEN"

# Production server - Balanced performance and cost
server_name = "prod-server"
server_type = "cx32"           # 8GB RAM, 4 vCPUs (~€17/month)
location    = "nbg1"           # Choose closest to your users
environment = "production"

# =============================================================================
# SSH CONFIGURATION
# =============================================================================

# ⚠️  Use dedicated production SSH keys - NEVER use development keys!
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAA... prod@yourdomain.com"

ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
YOUR_PRODUCTION_PRIVATE_KEY
-----END OPENSSH PRIVATE KEY-----
EOT

# =============================================================================
# ADMIN AUTHENTICATION
# =============================================================================

# ⚠️  Use a strong, unique password for production!
# Generate with: htpasswd -nbB admin $(openssl rand -base64 32) | cut -d: -f2 | base64 -w0
admin_password_hash = "YOUR_STRONG_PASSWORD_HASH"

# Production service hostnames
traefik_host       = "admin.yourdomain.com"
swarmpit_host      = "swarmpit.yourdomain.com"
dozzle_host        = "logs.yourdomain.com"
traefik_acme_email = "admin@yourdomain.com"     # Valid email for SSL notifications

# =============================================================================
# DOCKER CONFIGURATION
# =============================================================================

enable_docker_swarm = true

# =============================================================================
# ADDITIONAL DNS (Optional)
# =============================================================================

# Add production-specific DNS records as needed
additional_cname_records = [
  # Example: API endpoint
  # {
  #   name   = "api"
  #   target = "yourdomain.com."
  # }
]

additional_a_records = []

# =============================================================================
# PRODUCTION DEPLOYMENT CHECKLIST
# =============================================================================
#
# Before deploying to production:
#
# 1. Security:
#    ✓ Strong, unique admin password
#    ✓ Dedicated SSH keys (not shared with dev/staging)
#    ✓ MFA enabled on all Hetzner accounts
#    ✓ API tokens have minimum required permissions
#    ✓ Review firewall rules in compute module
#
# 2. DNS & SSL:
#    ✓ DNS zone properly configured
#    ✓ Valid email for SSL certificate notifications
#    ✓ Test DNS resolution before deployment
#
# 3. Backup & Recovery:
#    ✓ Plan backup strategy (database, configs, data)
#    ✓ Document recovery procedures
#    ✓ Test restore process
#
# 4. Monitoring:
#    ✓ Set up external monitoring (uptime checks)
#    ✓ Configure alerting for critical services
#    ✓ Review logs regularly
#
# 5. Cost Management:
#    ✓ Review server size (CX32 ~€17/month)
#    ✓ Consider backups (20% additional cost)
#    ✓ Set up billing alerts
#
# Deployment:
#   cd terraform/
#   terraform workspace select prod || terraform workspace new prod
#   terraform plan -var-file="../configs/prod.tfvars"
#   
#   # Review the plan carefully!
#   terraform apply -var-file="../configs/prod.tfvars"
#
# Post-Deployment:
#   - Verify all services are running
#   - Test SSL certificates
#   - Check monitoring dashboards
#   - Document server IP and access details
#   - Update DNS if needed
#
# Monthly Cost Estimate:
#   - CX32 Server: ~€17/month
#   - DNS Zone: Free
#   - Backups (optional): +20%
#   - Total: ~€17-20/month
#
# =============================================================================
