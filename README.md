# Infrastructure as Code - Docker Swarm on Hetzner Cloud

[![Terraform](https://img.shields.io/badge/Terraform-1.12+-purple.svg)](https://www.terraform.io/)
[![Docker Swarm](https://img.shields.io/badge/Docker-Swarm-blue.svg)](https://docs.docker.com/engine/swarm/)
[![Hetzner Cloud](https://img.shields.io/badge/Hetzner-Cloud-red.svg)](https://www.hetzner.com/cloud)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Production-ready Docker Swarm infrastructure on Hetzner Cloud with automated deployment. Supports both local Terraform and CI/CD workflows.**

## ✨ Features

- 🚀 **Automated Deployment** - Deploy via scripts or integrate with GitHub Actions
- 🌍 **Multi-Environment** - Dev, staging, and production support
- 🔒 **Secure by Default** - SSL certificates, firewall rules, and password protection
- 📊 **Built-in Monitoring** - Traefik dashboard, Swarmpit UI, and Dozzle logs
- 💰 **Cost-Effective** - Start from €8/month, scale as needed
- 🔧 **Interactive Setup** - Guided configuration with validation
- 🛠️ **Utility Scripts** - SSH key generation, password hashing, config validation

## 🏗️ Architecture

```
Local/CI → Terraform → Hetzner Cloud
              ↓
  ┌───────────┼───────────────┐
  │           │               │
Development Staging      Production
(cx23 4GB)  (cx33 8GB)   (cx43 16GB)
€2.99/mo    €4.99/mo     €8.99/mo
```

**Included Services:**
- **Traefik** - Automatic SSL/TLS and reverse proxy
- **Swarmpit** - Docker Swarm management UI
- **Dozzle** - Real-time container log viewer
- **Automatic DNS** - Managed via Hetzner DNS API

## � Quick Start

### Prerequisites

- [Hetzner Cloud](https://www.hetzner.com/cloud) account with API token
- [Hetzner DNS](https://dns.hetzner.com/) account with API token  
- Domain registered and configured in Hetzner DNS
- Terraform >= 1.12 (for local deployment)

### Installation

1. **Clone this repository**

   ```bash
   git clone https://github.com/YOUR_USERNAME/infrastructure.git
   cd infrastructure
   ```

2. **Generate SSH keys and password hash**

   ```bash
   # Generate SSH keys for server access
   ./scripts/utils/generate-ssh-keys.sh deploy ed25519
   
   # Generate admin password hash for Traefik/Swarmpit
   ./scripts/utils/generate-password.sh admin
   ```

3. **Setup environment configuration (Interactive)**

   ```bash
   # Interactive mode - prompts for all values
   ./scripts/setup-env.sh dev
   
   # Or use template mode
   ./scripts/setup-env.sh dev --from-template
   # Then edit: nano terraform/terraform.dev.tfvars
   ```

4. **Validate configuration**

   ```bash
   ./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars
   ```

5. **Deploy infrastructure**

   ```bash
   # With local backend
   ./scripts/deploy-env.sh dev apply --local
   
   # Or with Terraform Cloud (configure versions.tf first)
   ./scripts/deploy-env.sh dev apply
   ```

6. **Access your services**

   After deployment (5-10 minutes), access your management tools:

   - **Traefik Dashboard**: `https://admin.yourdomain.com`
   - **Swarmpit UI**: `https://swarmpit.yourdomain.com`
   - **Dozzle Logs**: `https://logs.yourdomain.com`

   Login credentials: `admin` / `<your-password>`

## 📁 Repository Structure

```
.
├── terraform/                  # Terraform infrastructure code
│   ├── main.tf                 # Main infrastructure definition
│   ├── variables.tf            # Variable definitions with validation
│   ├── outputs.tf              # Output definitions
│   ├── versions.tf             # Provider and backend configuration
│   └── modules/                # Reusable modules
│       ├── compute/            # Server provisioning module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── scripts/        # Server initialization scripts
│       │       ├── init-docker.sh
│       │       ├── init-docker-swarm.sh
│       │       └── deploy-services.sh
│       └── dns/                # DNS management module
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── configs/                    # Environment configurations
│   ├── template.tfvars         # Master configuration template
│   ├── dev.example.tfvars      # Development environment template
│   ├── prod.example.tfvars     # Production environment template
│   └── terraform.example.tfvars # Legacy template
├── scripts/                    # Automation scripts
│   ├── setup-env.sh            # Interactive environment setup
│   ├── deploy-env.sh           # Multi-environment deployment
│   └── utils/                  # Utility scripts
│       ├── generate-ssh-keys.sh    # SSH key generation
│       ├── generate-password.sh    # Password hash generation
│       └── validate-config.sh      # Configuration validation
├── docs/                       # Documentation
│   ├── quickstart.md           # 5-minute setup guide
│   ├── configuration.md        # Configuration reference
│   ├── deployment.md           # Deployment guide
│   └── troubleshooting.md      # Common issues and solutions
└── README.md                   # This file
```

## 🔧 Usage

### 🚀 Deploy New Environment

```bash
# Create configuration interactively
./scripts/setup-env.sh staging

# Or copy and edit template
cp configs/prod.example.tfvars terraform/terraform.prod.tfvars
nano terraform/terraform.prod.tfvars

# Validate configuration
./scripts/utils/validate-config.sh terraform/terraform.prod.tfvars

# Deploy
./scripts/deploy-env.sh prod apply --local
```

### 🔄 Update Infrastructure

```bash
# Modify configuration
nano terraform/terraform.prod.tfvars

# Preview changes
./scripts/deploy-env.sh prod plan --local

# Apply changes
./scripts/deploy-env.sh prod apply --local
```

### 🗑️ Destroy Environment

```bash
# Destroy infrastructure (requires confirmation)
./scripts/deploy-env.sh dev destroy --local
```

### 📊 View Outputs

```bash
# View deployment information
./scripts/deploy-env.sh dev output
```

## 🛠️ Configuration

### 📝 Required Configuration Values

Each environment requires a configuration file with these values:

```hcl
# Hetzner Credentials
hetzner_token       = "your-cloud-api-token"
hetzner_dns_token   = "your-dns-api-token"
hetzner_dns_zone_id = "your-zone-id"

# Domain Configuration
domain_name         = "yourdomain.com"
traefik_host        = "admin.yourdomain.com"
swarmpit_host       = "swarmpit.yourdomain.com"
dozzle_host         = "logs.yourdomain.com"
traefik_acme_email  = "admin@yourdomain.com"

# Server Configuration
server_name = "my-server"
server_type = "cx22"
location    = "nbg1"
environment = "development"

# SSH Keys
ssh_public_key  = "ssh-ed25519 AAAAC3..."
ssh_private_key = "-----BEGIN OPENSSH PRIVATE KEY-----\n..."

# Authentication
admin_password_hash = "admin:$2y$05$..."
```

See [docs/configuration.md](docs/configuration.md) for detailed explanations of all variables.

### 💻 Supported Server Types

| Type  | vCPU | RAM   | Storage | Price/month (approx.) | Recommended For |
|-------|------|-------|---------|-----------------------|-----------------|
| cx23  | 2    | 4 GB  | 40 GB   | €2.99                 | Development     |
| cx33  | 4    | 8 GB  | 80 GB   | €4.99                 | Staging         |
| cx43  | 8    | 16 GB | 160 GB  | €8.99                 | Production      |
| cx53  | 16   | 32 GB | 320 GB  | €16.99                | High Traffic    |

**Additional costs:**
- DNS Zones: Free
- Snapshots: €0.01/GB per month (optional)
- Backups: 20% of server price (optional)

💡 **Tip**: Start with cx23 for development and scale up as needed. Prices shown are approximate and may vary based on account discounts.

## � Monitoring & Management

### 🛠️ Built-in Tools

- **Traefik Dashboard** - View routing rules, SSL certificates, and service health
- **Swarmpit** - Manage Docker services, view logs, monitor resources
- **Dozzle** - Real-time container log viewer with search and filtering

All tools are accessible via your configured hostnames with basic authentication.

## �🔒 Security

- **Firewall**: Only ports 80, 443, and 22 exposed
- **SSL/TLS**: Automatic certificates via Let's Encrypt
- **Authentication**: Admin tools protected with bcrypt password hashing
- **SSH**: Key-based authentication only (password auth disabled)
- **Secrets**: Never committed to Git (.gitignore configured)
- **Validation**: Built-in configuration validation before deployment

### Security Best Practices

- Generate unique SSH keys for each environment
- Use strong passwords (12+ characters)
- Rotate credentials regularly
- Enable MFA on Hetzner account
- Review firewall rules periodically
- Keep server software updated

See [docs/configuration.md](docs/configuration.md) for detailed security recommendations.

## 📝 Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[quickstart.md](docs/quickstart.md)** - Get started in 5 minutes
- **[configuration.md](docs/configuration.md)** - Complete configuration reference
- **[deployment.md](docs/deployment.md)** - Deployment options and workflows
- **[troubleshooting.md](docs/troubleshooting.md)** - Common issues and solutions

## 🔧 Troubleshooting

### Common Issues

**Configuration validation fails**
```bash
# Re-run validation with detailed output
./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars

# Check file permissions
chmod 600 terraform/terraform.dev.tfvars
```

**Terraform init fails**
```bash
cd terraform/
rm -rf .terraform/ .terraform.lock.hcl
terraform init
```

**DNS not resolving**
```bash
# Check DNS records
dig +short yourdomain.com

# Verify Hetzner DNS zone ID
# Login to https://dns.hetzner.com/ and check zone ID
```

**SSL certificates not generating**
```bash
# SSH to server and check Traefik logs
ssh -i ~/.ssh/deploy_ed25519 root@YOUR_SERVER_IP
docker service logs traefik

# Common causes:
# - DNS not propagated (wait 5-10 minutes)
# - Port 80/443 not accessible
# - Invalid email address
```

**Services not accessible**
```bash
# Check service status
ssh -i ~/.ssh/deploy_ed25519 root@YOUR_SERVER_IP
docker service ls
docker service ps traefik swarmpit dozzle

# View logs
docker service logs <service-name>
```

For more detailed troubleshooting, see [docs/troubleshooting.md](docs/troubleshooting.md).

## 🚀 Advanced Usage

### Using Terraform Cloud Backend

1. Update `terraform/versions.tf` to use Terraform Cloud:
```hcl
terraform {
  cloud {
    organization = "YOUR_ORGANIZATION"
    workspaces {
      name = "project-dev"
    }
  }
}
```

2. Deploy without `--local` flag:
```bash
./scripts/deploy-env.sh dev apply
```

### Manual Terraform Commands

```bash
cd terraform/

# Initialize
terraform init

# Plan with specific var file
terraform plan -var-file="terraform.dev.tfvars"

# Apply changes
terraform apply -var-file="terraform.dev.tfvars"

# View outputs
terraform output

# Destroy infrastructure
terraform destroy -var-file="terraform.dev.tfvars"
```

### Multi-Environment Management

Manage multiple environments simultaneously:

```bash
# Setup all environments
./scripts/setup-env.sh dev
./scripts/setup-env.sh staging
./scripts/setup-env.sh prod

# Deploy all environments
./scripts/deploy-env.sh dev apply --local
./scripts/deploy-env.sh staging apply --local
./scripts/deploy-env.sh prod apply

# View all environment outputs
for env in dev staging prod; do
  echo "=== $env ==="
  ./scripts/deploy-env.sh $env output
done
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Dockerswarm.rocks](https://dockerswarm.rocks/) - Docker Swarm best practices
- [Hetzner Cloud](https://www.hetzner.com/cloud) - Affordable cloud infrastructure
- [Traefik](https://traefik.io/) - Modern reverse proxy and load balancer
- [Swarmpit](https://swarmpit.io/) - Docker Swarm management interface
- [Dozzle](https://dozzle.dev/) - Real-time log viewer for Docker

## 📞 Support

- **Documentation**: See `docs/` directory for detailed guides
- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: Ask questions in GitHub Discussions

---

**Made with ❤️ for the DevOps community**
