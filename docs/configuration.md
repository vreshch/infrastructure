# Configuration Reference

Complete guide to all configuration variables and options for your Docker Swarm infrastructure.

## Table of Contents

- [Configuration File Locations](#configuration-file-locations)
- [Required Variables](#required-variables)
- [Optional Variables](#optional-variables)
- [Environment-Specific Recommendations](#environment-specific-recommendations)
- [Security Best Practices](#security-best-practices)
- [Advanced Configuration](#advanced-configuration)

## Configuration File Locations

Configuration files are stored in the `terraform/` directory:

```
terraform/
├── terraform.dev.tfvars      # Development environment
├── terraform.staging.tfvars  # Staging environment
└── terraform.prod.tfvars     # Production environment
```

**Templates** are available in `configs/`:
- `configs/template.tfvars` - Master template with all options
- `configs/dev.example.tfvars` - Development-optimized template
- `configs/prod.example.tfvars` - Production-optimized template

## Required Variables

### Hetzner Cloud Credentials

#### `hetzner_token`
- **Type**: String (sensitive)
- **Description**: Hetzner Cloud API token for server provisioning
- **How to get**: [Hetzner Cloud Console](https://console.hetzner.cloud/) → Project → Security → API Tokens
- **Permissions**: Read & Write
- **Example**: `"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"`

#### `hetzner_dns_token`
- **Type**: String (sensitive)
- **Description**: Hetzner DNS API token for DNS record management
- **How to get**: [Hetzner DNS Console](https://dns.hetzner.com/) → API Tokens
- **Permissions**: Read & Write for specific zone
- **Example**: `"yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"`

#### `hetzner_dns_zone_id`
- **Type**: String
- **Description**: DNS Zone ID where records will be created
- **How to get**: Hetzner DNS Console → Select your domain → Zone ID in URL
- **Example**: `"zzzzzzzzzzzzzzzzzzzzzzzzzz"`

### Domain Configuration

#### `domain_name`
- **Type**: String
- **Description**: Primary domain for your infrastructure
- **Validation**: Must be valid domain format (e.g., `example.com` or `sub.example.com`)
- **Example Dev**: `"dev.example.com"`
- **Example Prod**: `"example.com"`
- **DNS Requirements**: Must have a zone configured in Hetzner DNS

#### `traefik_host`
- **Type**: String
- **Description**: Hostname for Traefik admin dashboard
- **Validation**: Must be valid hostname
- **Example Dev**: `"admin.dev.example.com"`
- **Example Prod**: `"admin.example.com"`
- **Access**: `https://{traefik_host}` (basic auth protected)

#### `swarmpit_host`
- **Type**: String
- **Description**: Hostname for Swarmpit management UI
- **Validation**: Must be valid hostname
- **Example Dev**: `"swarmpit.dev.example.com"`
- **Example Prod**: `"swarmpit.example.com"`
- **Access**: `https://{swarmpit_host}` (basic auth protected)

#### `dozzle_host`
- **Type**: String
- **Description**: Hostname for Dozzle log viewer
- **Validation**: Must be valid hostname
- **Example Dev**: `"logs.dev.example.com"`
- **Example Prod**: `"logs.example.com"`
- **Access**: `https://{dozzle_host}` (basic auth protected)

#### `traefik_acme_email`
- **Type**: String
- **Description**: Email for Let's Encrypt certificate notifications
- **Validation**: Must be valid email format
- **Example**: `"admin@example.com"`
- **Important**: Use a monitored email for certificate expiration alerts

### Server Configuration

#### `server_name`
- **Type**: String
- **Description**: Name for the Hetzner Cloud server
- **Validation**: Lowercase letters, numbers, and hyphens only
- **Example Dev**: `"dev-server"`
- **Example Prod**: `"prod-server"`
- **Visible**: In Hetzner Cloud Console

#### `server_type`
- **Type**: String
- **Description**: Hetzner server type determining CPU, RAM, and storage
- **Validation**: Must be valid Hetzner server type
- **Options**:
  - `cx11` - 1 vCPU, 2GB RAM, 20GB SSD - €4/month (too small, not recommended)
  - `cx21` - 2 vCPU, 4GB RAM, 40GB SSD - €6/month (minimal)
  - `cx22` - 2 vCPU, 4GB RAM, 40GB SSD - €8/month **(recommended for dev)**
  - `cx31` - 2 vCPU, 8GB RAM, 80GB SSD - €12/month
  - `cx32` - 4 vCPU, 8GB RAM, 80GB SSD - €17/month **(recommended for staging)**
  - `cx41` - 4 vCPU, 16GB RAM, 160GB SSD - €25/month
  - `cx42` - 8 vCPU, 16GB RAM, 160GB SSD - €33/month **(recommended for production)**
  - `cx51` - 8 vCPU, 32GB RAM, 240GB SSD - €49/month
  - `cx52` - 16 vCPU, 32GB RAM, 320GB SSD - €65/month
- **Example Dev**: `"cx22"`
- **Example Prod**: `"cx42"`

#### `location`
- **Type**: String
- **Description**: Hetzner datacenter location
- **Validation**: Must be valid location code
- **Options**:
  - `nbg1` - Nuremberg, Germany (default)
  - `fsn1` - Falkenstein, Germany
  - `hel1` - Helsinki, Finland
  - `ash` - Ashburn, VA, USA
  - `hil` - Hillsboro, OR, USA
- **Example**: `"nbg1"`
- **Considerations**: Choose closest to your users for best latency

#### `environment`
- **Type**: String
- **Description**: Environment name for labeling and identification
- **Common Values**: `"development"`, `"staging"`, `"production"`
- **Example Dev**: `"development"`
- **Example Prod**: `"production"`
- **Used For**: Server labels, resource tagging

### SSH Configuration

#### `ssh_public_key`
- **Type**: String (multi-line)
- **Description**: SSH public key for server access
- **Format**: Must start with `ssh-rsa`, `ssh-ed25519`, etc.
- **Generation**: `./scripts/utils/generate-ssh-keys.sh deploy ed25519`
- **Example**:
```hcl
ssh_public_key = <<-EOT
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx deploy-20251018
EOT
```
- **Security**: Can be safely committed to Git (it's public)

#### `ssh_private_key`
- **Type**: String (multi-line, sensitive)
- **Description**: SSH private key for server access
- **Format**: Must be in PEM format with header/footer
- **Generation**: Same as public key
- **Example**:
```hcl
ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
... (many lines) ...
-----END OPENSSH PRIVATE KEY-----
EOT
```
- **Security**: NEVER commit to Git! Listed in .gitignore

### Authentication

#### `admin_password_hash`
- **Type**: String (sensitive)
- **Description**: Bcrypt password hash for admin authentication
- **Format**: htpasswd format: `username:$2y$05$...`
- **Generation**: `./scripts/utils/generate-password.sh admin`
- **Example**: `"admin:$2y$05$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"`
- **Used For**: Traefik, Swarmpit, and Dozzle basic authentication
- **Security**: Never use plain passwords, always use bcrypt hashes

## Optional Variables

### Project Configuration

#### `project_name`
- **Type**: String
- **Default**: `"infrastructure"`
- **Description**: Project name for resource labeling
- **Example**: `"my-project"`

### DNS Configuration

#### `ttl`
- **Type**: Number
- **Default**: `300` (5 minutes)
- **Range**: 60 - 86400 seconds
- **Description**: TTL for DNS records
- **Recommendations**:
  - Development: `60` (fast updates)
  - Production: `3600` (stability)

#### `enable_www_redirect`
- **Type**: Boolean
- **Default**: `true`
- **Description**: Create www CNAME record
- **Example**: `false` if you don't use www subdomain

#### `additional_cname_records`
- **Type**: List of objects
- **Default**: `[]`
- **Description**: Additional CNAME records to create
- **Example**:
```hcl
additional_cname_records = [
  {
    name   = "www"
    target = "example.com."
  },
  {
    name   = "api"
    target = "example.com."
  }
]
```

#### `additional_a_records`
- **Type**: List of objects
- **Default**: `[]`
- **Description**: Additional A records to create
- **Example**:
```hcl
additional_a_records = [
  {
    name  = "api"
    value = "192.168.1.1"
  }
]
```

### Docker Swarm Configuration

#### `enable_docker_swarm`
- **Type**: Boolean
- **Default**: `true`
- **Description**: Whether to initialize Docker Swarm
- **Recommendation**: Keep `true` unless you have specific reasons

## Environment-Specific Recommendations

### Development Environment

**Goal**: Cost-effective testing environment

```hcl
# Minimal resources
server_type = "cx22"           # €8/month
location    = "nbg1"           # Closest to you
environment = "development"

# Fast DNS updates
ttl = 60

# Aggressive certificate renewal for testing
# (uses default Let's Encrypt settings)

# Naming convention
server_name    = "dev-server"
domain_name    = "dev.example.com"
traefik_host   = "admin.dev.example.com"
swarmpit_host  = "swarmpit.dev.example.com"
dozzle_host    = "logs.dev.example.com"
```

**Tips**:
- Destroy when not in use to save costs
- Use separate domain (e.g., `dev.example.com`)
- Test deployments and updates here first

### Staging Environment

**Goal**: Production-like testing

```hcl
# Balanced resources
server_type = "cx32"           # €17/month
location    = "nbg1"           # Same as production
environment = "staging"

# Medium DNS TTL
ttl = 300

# Production-like naming
server_name    = "staging-server"
domain_name    = "staging.example.com"
traefik_host   = "admin.staging.example.com"
swarmpit_host  = "swarmpit.staging.example.com"
dozzle_host    = "logs.staging.example.com"
```

**Tips**:
- Use production-like resource sizes
- Test full deployment workflow
- Validate SSL certificate generation
- Performance testing

### Production Environment

**Goal**: Reliable, secure production infrastructure

```hcl
# Production resources
server_type = "cx42"           # €33/month
location    = "nbg1"           # Closest to users
environment = "production"

# Stable DNS
ttl = 3600

# Clean naming
server_name    = "prod-server"
domain_name    = "example.com"
traefik_host   = "admin.example.com"
swarmpit_host  = "swarmpit.example.com"
dozzle_host    = "logs.example.com"
```

**Additional Requirements**:
- Unique SSH keys (not shared with dev/staging)
- Strong, unique admin password
- Monitored email for SSL certificates
- Regular backups configured
- Monitoring and alerting setup
- Documented disaster recovery plan

## Security Best Practices

### Credential Management

1. **Never commit secrets to Git**
   ```bash
   # Verify .gitignore
   git status
   # Should not show *.tfvars files
   ```

2. **Use unique credentials per environment**
   - Different SSH keys for dev/staging/prod
   - Different admin passwords
   - Different API tokens (if possible)

3. **Rotate credentials regularly**
   - SSH keys: Every 90 days
   - Passwords: Every 60 days
   - API tokens: Every 180 days

4. **Secure file permissions**
   ```bash
   chmod 600 terraform/*.tfvars
   chmod 600 ~/.ssh/deploy_*
   ```

### Password Security

1. **Generate strong passwords**
   ```bash
   # Use password generator
   openssl rand -base64 32
   
   # Or use dedicated tool
   ./scripts/utils/generate-password.sh admin
   ```

2. **Password requirements**
   - Minimum 12 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - No dictionary words
   - Unique per environment

3. **Store securely**
   - Use password manager (1Password, LastPass, Bitwarden)
   - Never store in plain text
   - Never share via email/chat

### SSH Key Security

1. **Use Ed25519 keys** (more secure than RSA)
   ```bash
   ./scripts/utils/generate-ssh-keys.sh deploy ed25519
   ```

2. **Protect private keys**
   ```bash
   chmod 600 ~/.ssh/deploy_ed25519
   # Never copy to shared locations
   # Never commit to Git
   ```

3. **Use SSH agent**
   ```bash
   ssh-add ~/.ssh/deploy_ed25519
   # Enter passphrase once per session
   ```

### Network Security

1. **Firewall rules** (automatically configured):
   - Port 22 (SSH): Limited to necessary IPs
   - Port 80 (HTTP): ACME challenge only
   - Port 443 (HTTPS): Public
   - Port 2377 (Swarm): Closed to public

2. **SSL/TLS**:
   - Automatic Let's Encrypt certificates
   - TLS 1.2+ only
   - Strong cipher suites
   - HSTS enabled

3. **Authentication**:
   - Basic auth on all admin interfaces
   - Bcrypt password hashing
   - No default credentials

## Advanced Configuration

### Custom Firewall Rules

Edit `terraform/modules/compute/main.tf`:

```hcl
resource "hcloud_firewall" "server_firewall" {
  name = "${var.server_name}-firewall"

  # Add custom rule
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "3000"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}
```

### Custom DNS Records

In your `terraform.*.tfvars`:

```hcl
additional_cname_records = [
  {
    name   = "www"
    target = "${var.domain_name}."
  },
  {
    name   = "api"
    target = "${var.domain_name}."
  },
  {
    name   = "status"
    target = "${var.domain_name}."
  }
]

additional_a_records = [
  {
    name  = "monitor"
    value = "192.168.1.100"
  }
]
```

### Resource Limits

Edit `terraform/modules/compute/scripts/deploy-services.sh` to adjust Docker service resources:

```bash
# Traefik resources
--limit-memory="512M"    # Max memory
--reserve-memory="128M"  # Reserved memory
--limit-cpu="1.0"        # Max CPU

# Adjust based on server_type
```

### Backend Configuration

#### Local Backend (Default)

No configuration needed. State stored in `terraform/terraform.tfstate`.

#### Terraform Cloud

Edit `terraform/versions.tf`:

```hcl
terraform {
  cloud {
    organization = "your-org"
    workspaces {
      name = "infrastructure-dev"
    }
  }
}
```

#### S3 Backend

Edit `terraform/versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "infrastructure/dev/terraform.tfstate"
    region = "eu-central-1"
  }
}
```

## Configuration Validation

Always validate your configuration before deployment:

```bash
# Validate configuration file
./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars

# Validate Terraform syntax
cd terraform/
terraform validate

# Preview changes
terraform plan -var-file="terraform.dev.tfvars"
```

## Common Mistakes to Avoid

1. **Using weak passwords**
   - ❌ `password123`
   - ✅ Use `generate-password.sh` tool

2. **Committing secrets to Git**
   - ❌ `git add terraform.dev.tfvars`
   - ✅ Files are .gitignored by default

3. **Same credentials across environments**
   - ❌ Copy prod config to dev
   - ✅ Generate unique credentials per environment

4. **Wrong domain format**
   - ❌ `https://example.com` (includes protocol)
   - ✅ `example.com` (domain only)

5. **Invalid server type**
   - ❌ `"CX22"` (uppercase)
   - ✅ `"cx22"` (lowercase)

6. **Missing DNS configuration**
   - ❌ Domain not in Hetzner DNS
   - ✅ Configure zone first, then get zone ID

## Next Steps

- **Deploy**: See [deployment.md](deployment.md)
- **Troubleshoot**: See [troubleshooting.md](troubleshooting.md)
- **Quick Start**: See [quickstart.md](quickstart.md)

---

**Need Help?** Check [troubleshooting.md](troubleshooting.md) or open a GitHub Issue.
