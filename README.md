# Infrastructure as Code - Docker Swarm on Hetzner Cloud

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple.svg)](https://www.terraform.io/)
[![Docker Swarm](https://img.shields.io/badge/Docker-Swarm-blue.svg)](https://docs.docker.com/engine/swarm/)
[![Hetzner Cloud](https://img.shields.io/badge/Hetzner-Cloud-red.svg)](https://www.hetzner.com/cloud)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Production-ready Docker Swarm infrastructure on Hetzner Cloud, deployed automatically via GitHub Actions. Zero local setup required.**

## ✨ Features

- 🚀 **Automated Deployment** - GitHub Actions handles everything
- 🌍 **Multi-Environment** - Dev, staging, and production support
- 🔒 **Secure by Default** - SSL certificates, firewall rules, and encrypted secrets
- 📊 **Built-in Monitoring** - Traefik dashboard, Swarmpit UI, and Dozzle logs
- 💰 **Cost-Effective** - Start from €9/month, scale as needed
- 🔧 **Zero Local Setup** - No Terraform installation required

## 🏗️ Architecture

```
GitHub Actions → Terraform → Hetzner Cloud
                    ↓
    ┌───────────────┼───────────────┐
    │               │               │
Development    Staging        Production
(CX22 4GB)     (CX32 8GB)     (CX42 16GB)
€8/month       €17/month      €33/month
```

**Included Services:**
- **Traefik** - Automatic SSL/TLS and reverse proxy
- **Swarmpit** - Docker Swarm management UI
- **Dozzle** - Real-time container log viewer
- **Automatic DNS** - Managed via Hetzner DNS API

### 📋 Prerequisites

Before you begin, ensure you have:

- GitHub account
- [Hetzner Cloud](https://www.hetzner.com/cloud) account with API token
- [Hetzner DNS](https://dns.hetzner.com/) account with API token
- Two domains registered (one for infrastructure, one for applications)

### ⚙️ Installation

1. **Clone this repository**

   ```bash
   git clone https://github.com/vreshch/infrastructure.git
   cd infrastructure
   ```

2. **Configure GitHub Secrets**

   Go to your repository settings → Secrets and variables → Actions, and add:

   ```
   HETZNER_CLOUD_TOKEN       # Your Hetzner Cloud API token
   HETZNER_DNS_TOKEN         # Your Hetzner DNS API token
   HETZNER_DNS_ZONE_ID_INFRA # DNS Zone ID for infrastructure domain
   SSH_PUBLIC_KEY            # Your SSH public key
   SSH_PRIVATE_KEY           # Your SSH private key
   ADMIN_PASSWORD_HASH       # Bcrypt hash for admin password
   ```

3. **Create environment configuration**

   ```bash
   cp configs/example.tfvars configs/dev.tfvars
   ```

   Edit `configs/dev.tfvars` with your settings:

   ```hcl
   environment           = "dev"
   server_type           = "cx22"
   infrastructure_domain = "infra.yourdomain.com"
   admin_email           = "admin@yourdomain.com"
   ```

4. **Deploy via GitHub Actions**

   ```bash
   git checkout -b dev
   git add configs/dev.tfvars
   git commit -m "Add dev environment configuration"
   git push origin dev
   ```

   GitHub Actions will automatically deploy your infrastructure!

5. **Access your infrastructure**

   After deployment completes (5-10 minutes), access your management tools:

   - **Traefik Dashboard**: `https://admin.dev.infra.yourdomain.com`
   - **Swarmpit UI**: `https://swarmpit.dev.infra.yourdomain.com`
   - **Dozzle Logs**: `https://logs.dev.infra.yourdomain.com`

## 📁 Repository Structure

```
.
├── .github/
│   └── workflows/              # GitHub Actions workflows
│       ├── deploy.yml          # Deploy infrastructure
│       ├── plan.yml            # Preview changes
│       └── destroy.yml         # Destroy infrastructure
├── terraform/                  # Terraform configuration
│   ├── main.tf                 # Main infrastructure definition
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Output definitions
│   └── modules/                # Reusable modules
│       ├── swarm-node/         # Docker Swarm node configuration
│       └── dns-records/        # DNS record management
├── configs/                    # Environment configurations
│   ├── example.tfvars          # Configuration template
│   ├── dev.tfvars              # Development environment
│   ├── staging.tfvars          # Staging environment
│   └── prod.tfvars             # Production environment
├── scripts/                    # Automation scripts
│   ├── setup.sh                # Environment setup
│   ├── deploy.sh               # Deployment automation
│   └── utils/                  # Utility scripts
│       ├── generate-ssh-keys.sh    # SSH key generation
│       └── generate-password.sh    # Password hash generation
├── docs/                       # Documentation
│   ├── README.md               # Documentation index
│   ├── quickstart.md           # 5-minute setup guide
│   ├── requirements.md         # Detailed requirements
│   ├── github-actions.md       # GitHub Actions setup
│   └── manual-deploy.md        # Manual deployment guide
└── README.md                   # This file
```

## 🔧 Usage

### 🚀 Deploy New Environment

```bash
# Create configuration
cp configs/dev.tfvars configs/staging.tfvars
vim configs/staging.tfvars

# Deploy via branch
git checkout -b staging
git add configs/staging.tfvars
git commit -m "Add staging environment"
git push origin staging
```

### 🔄 Update Infrastructure

```bash
# Modify configuration
vim configs/prod.tfvars

# Commit and push
git add configs/prod.tfvars
git commit -m "Update production server size"
git push origin main
```

### 🗑️ Destroy Environment

Use the GitHub Actions UI:
1. Go to **Actions** → **Destroy Infrastructure**
2. Click **Run workflow**
3. Select the environment to destroy
4. Type `destroy` to confirm

## 🛠️ Manual Deployment (Local Terraform)

For local development and debugging, you can deploy infrastructure manually using Terraform. This repository includes automation scripts to simplify the process.

### 🚀 Quick Start with Automation Scripts

```bash
# 1. Setup environment configuration
./scripts/setup.sh dev  # Creates config from template

# 2. Edit configuration with your values
nano configs/dev.tfvars

# 3. Deploy using automation script
./scripts/deploy.sh dev plan   # Preview changes
./scripts/deploy.sh dev apply  # Deploy infrastructure
./scripts/deploy.sh dev output # View outputs
```

### 💻 Manual Terraform Commands

```bash
cd terraform/

# Initialize and deploy
terraform init
terraform plan -var-file="../configs/dev.tfvars"
terraform apply -var-file="../configs/dev.tfvars"

# View deployment info
terraform output
```

### 📋 Required Configuration

Create `configs/dev.tfvars` with your settings:

```hcl
# Domain & DNS
domain_name         = "dev.yourdomain.com"
hetzner_dns_zone_id = "your-zone-id"
hetzner_dns_token   = "your-dns-token"

# Cloud & Server
hetzner_token = "your-cloud-token"
server_type   = "cx22"
environment   = "development"

# SSH Keys
ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2E..."
ssh_private_key = "-----BEGIN OPENSSH PRIVATE KEY-----\n..."

# Services
admin_password_hash = "base64-htpasswd-hash"
traefik_host       = "traefik.dev.yourdomain.com"
swarmpit_host      = "swarmpit.dev.yourdomain.com"
dozzle_host        = "logs.dev.yourdomain.com"
traefik_acme_email = "admin@yourdomain.com"
```

### 🔐 Generate Credentials

```bash
# Admin password hash (for Traefik basic auth)
./scripts/utils/generate-password.sh yourpassword

# Or manually:
htpasswd -nbB admin yourpassword | cut -d: -f2 | base64 -w0

# SSH keys for server access
./scripts/utils/generate-ssh-keys.sh

# Or manually:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/deploy_rsa
cat ~/.ssh/deploy_rsa.pub     # Public key
cat ~/.ssh/deploy_rsa          # Private key
```

### 🌐 Multi-Environment Management

```bash
# Development
./scripts/deploy.sh dev apply

# Staging
./scripts/deploy.sh staging apply

# Production (requires confirmation)
./scripts/deploy.sh prod apply
```

### 🗑️ Destroy Infrastructure

```bash
# Using automation script
./scripts/deploy.sh dev destroy

# Or manually
cd terraform/
terraform destroy -var-file="../configs/dev.tfvars"
```

### 📦 Included Scripts

This repository includes the following automation scripts:

- `scripts/setup.sh` - Environment setup automation
- `scripts/deploy.sh` - Deployment automation with safety checks
- `scripts/utils/generate-ssh-keys.sh` - SSH key pair generation
- `scripts/utils/generate-password.sh` - Password hash generation
- `configs/example.tfvars` - Configuration template

### 🔧 Troubleshooting

```bash
# Terraform state issues
cd terraform/
rm -rf .terraform/ && terraform init

# Check DNS resolution
dig +short dev.yourdomain.com

# Check SSL certificate generation (wait 5-10 minutes)
ssh root@dev.yourdomain.com
docker logs traefik

# View all container logs
docker service logs <service-name>
```

## Pricing

| Environment | Server Type | vCPU | RAM   | Storage | Monthly Cost |
|-------------|-------------|------|-------|---------|--------------|
| Development | CX23        | 2    | 4 GB  | 40 GB   | €3.49        |
| Staging     | CX32        | 4    | 8 GB  | 80 GB   | €5.49        |
| Production  | CX43        | 8    | 16 GB | 160 GB  | €9.49        |

**Additional costs:**
- DNS Zones: free of charge
- Backups: 20% of server price (optional)


💡 **Cost savings tip**: Destroy development environments when not in use!



## 🛠️ Configuration

### 📝 Environment Variables

Each environment is configured via `.tfvars` files in the `configs/` directory:

```hcl
# Required
environment           = "dev"           # Environment name
server_type           = "cx22"          # Hetzner server type
infrastructure_domain = "infra.io"      # Domain for management tools

# Optional
location              = "nbg1"          # Hetzner datacenter location
admin_email           = "admin@myapp.io" # Email for SSL certificates
enable_backups        = false           # Enable automated backups
```

### 💻 Supported Server Types

| Type  | vCPU | RAM   | Storage | Price/month |
|-------|------|-------|---------|-------------|
| CX22  | 2    | 4 GB  | 40 GB   | €8          |
| CX32  | 4    | 8 GB  | 80 GB   | €17         |
| CX42  | 8    | 16 GB | 160 GB  | €33         |
| CX52  | 16   | 32 GB | 320 GB  | €65         |

## 📊 Monitoring & Management

### 🛠️ Built-in Tools

- **Traefik Dashboard** (`admin.{env}.{infra-domain}`)
  - View routing rules
  - Monitor SSL certificates
  - Check service health

- **Swarmpit** (`swarmpit.{env}.{infra-domain}`)
  - Manage Docker services
  - View container logs
  - Monitor resource usage
  - Deploy new stacks

- **Dozzle** (`logs.{env}.{infra-domain}`)
  - Real-time container logs
  - Multi-container log streaming
  - Search and filter logs

### ⚡ GitHub Actions Workflows

- **Deploy** - Triggered on push to environment branches
- **Plan** - Preview infrastructure changes
- **Destroy** - Safely destroy infrastructure (manual trigger)

## 🔒 Security

- **Firewall**: Only ports 80, 443, and 22 exposed
- **SSL/TLS**: Automatic certificates via Let's Encrypt
- **Authentication**: Admin tools protected with basic auth
- **SSH**: Key-based authentication only
- **Secrets**: Managed via GitHub Secrets (encrypted)

## 📝 Documentation

Detailed documentation is available in the `docs/` directory:

- **[README.md](docs/README.md)** - Documentation index
- **[quickstart.md](docs/quickstart.md)** - 5-minute setup guide
- **[requirements.md](docs/requirements.md)** - Architecture overview and requirements
- **[github-actions.md](docs/github-actions.md)** - Complete GitHub Actions setup
- **[manual-deploy.md](docs/manual-deploy.md)** - Manual deployment guide

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Dockerswarm.rocks](https://dockerswarm.rocks/) - Docker Swarm setup documentation
- [Hetzner Cloud](https://www.hetzner.com/cloud) - Cloud infrastructure provider
- [Docker Swarm](https://docs.docker.com/engine/swarm/) - Container orchestration
- [Traefik](https://traefik.io/) - Modern reverse proxy
- [Swarmpit](https://swarmpit.io/) - Docker Swarm management UI
- [Dozzle](https://dozzle.dev/) - Container log viewer

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/vreshch/infrastructure/issues)
- **Documentation**: See `docs/` directory
- **Community**: [Discussions](https://github.com/vreshch/infrastructure/discussions)

---

**Made with ❤️ for the DevOps community**
