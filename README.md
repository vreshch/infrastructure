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
   cp environments/dev.tfvars.example environments/dev.tfvars
   ```

   Edit `environments/dev.tfvars` with your settings:

   ```hcl
   environment           = "dev"
   server_type           = "cx22"
   infrastructure_domain = "infra.yourdomain.com"
   admin_email           = "admin@yourdomain.com"
   ```

4. **Deploy via GitHub Actions**

   ```bash
   git checkout -b dev
   git add environments/dev.tfvars
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
│   └── workflows/           # GitHub Actions workflows
│       ├── deploy.yml       # Deploy infrastructure
│       ├── plan.yml         # Preview changes
│       └── destroy.yml      # Destroy infrastructure
├── docs/
│   ├── requirements.md      # Detailed requirements
│   ├── github-actions-setup.md  # Setup guide
│   └── setup-guide.md       # Manual setup (optional)
├── infrastructure/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output definitions
│   └── modules/             # Terraform modules
│       ├── compute/         # Server provisioning
│       └── dns/             # DNS management
├── environments/
│   ├── dev.tfvars.example   # Development config template
│   ├── staging.tfvars.example   # Staging config template
│   └── prod.tfvars.example  # Production config template
└── README.md                # This file
```

## 🔧 Usage

### 🚀 Deploy New Environment

```bash
# Create configuration
cp environments/dev.tfvars environments/staging.tfvars
vim environments/staging.tfvars

# Deploy via branch
git checkout -b staging
git add environments/staging.tfvars
git commit -m "Add staging environment"
git push origin staging
```

### 🔄 Update Infrastructure

```bash
# Modify configuration
vim environments/prod.tfvars

# Commit and push
git add environments/prod.tfvars
git commit -m "Update production server size"
git push origin main
```

### 🗑️ Destroy Environment

Use the GitHub Actions UI:
1. Go to **Actions** → **Destroy Infrastructure**
2. Click **Run workflow**
3. Select the environment to destroy
4. Type `destroy` to confirm

## 💰 Pricing

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

Each environment is configured via `.tfvars` files in the `environments/` directory:

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

- **[requirements.md](docs/requirements.md)** - Architecture overview and requirements
- **[github-actions-setup.md](docs/github-actions-setup.md)** - Complete setup guide
- **[setup-guide.md](docs/setup-guide.md)** - Manual setup for local development

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Dockerswarm.rocks](https://dockerswarm.rocks/) - Docker Swarm Rocks - setup documentation
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
