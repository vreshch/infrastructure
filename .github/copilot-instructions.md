# Infrastructure as Code - Docker Swarm on Hetzner Cloud

## 📋 Project Overview

Production-ready Docker Swarm infrastructure on Hetzner Cloud with automated deployment. Supports multi-environment (dev/staging/prod) with Traefik, Swarmpit, and Dozzle.

## 🏗️ Architecture

- **IaC**: Terraform 1.12+ with modular structure (compute + DNS modules)
- **Provider**: Hetzner Cloud (cx23-cx53, €2.99-€16.99/mo approx.)
- **Container Orchestration**: Docker Swarm (single-node, expandable)
- **Reverse Proxy**: Traefik v2.10 with automatic Let's Encrypt SSL
- **Management**: Swarmpit UI, Dozzle log viewer
- **DNS**: Automated via Hetzner DNS API

## 📁 Key Files

```
terraform/          # Infrastructure code (main.tf, modules/)
configs/            # Environment templates (template.tfvars, *.example.tfvars)
scripts/            # Automation (setup-env.sh, deploy-env.sh, utils/)
docs/               # Comprehensive documentation (see below)
```

## 🔧 Common Workflows

### Setup New Environment
```bash
# Generate credentials
./scripts/utils/generate-ssh-keys.sh deploy ed25519
./scripts/utils/generate-password.sh admin

# Interactive configuration
./scripts/setup-env.sh dev

# Validate
./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars

# Deploy
./scripts/deploy-env.sh dev apply --local
```

### Update Infrastructure
```bash
# Edit config
nano terraform/terraform.prod.tfvars

# Preview and apply
./scripts/deploy-env.sh prod plan --local
./scripts/deploy-env.sh prod apply --local
```

## 📖 Documentation References

When helping with this project, refer users to:

- **Quick Start**: `docs/quickstart.md` - 5-minute setup guide with prerequisites
- **Configuration**: `docs/configuration.md` - Complete variable reference, security best practices
- **Deployment**: `docs/deployment.md` - Local vs Cloud workflows, multi-environment management
- **Troubleshooting**: `docs/troubleshooting.md` - Common issues across 9 categories (config, terraform, DNS, SSL, Docker Swarm, services, network, performance)

## 🔑 Key Configuration Variables

**Required**: `hetzner_token`, `hetzner_dns_token`, `hetzner_dns_zone_id`, `domain_name`, `ssh_public_key`, `ssh_private_key`, `admin_password_hash`, `traefik_acme_email`

**Server Types**: cx23 (dev), cx33 (staging), cx43 (prod), cx53 (high-traffic)

**Environments**: `dev` (cx23, €2.99/mo), `staging` (cx33, €4.99/mo), `prod` (cx43+, €8.99+/mo)

## 🛠️ Utility Scripts

- `generate-ssh-keys.sh <name> <type>` - Generate ed25519/rsa keys with proper permissions
- `generate-password.sh <username>` - Generate bcrypt hash for Traefik/Swarmpit auth
- `validate-config.sh <tfvars-file>` - Validate all required fields and formats
- `setup-env.sh <env> [--interactive|--from-template]` - Create environment configuration
- `deploy-env.sh <env> <action> [--local]` - Deploy/destroy infrastructure

## 🔒 Security Notes

- Never commit: `*.tfvars` (except examples), `*.tfstate`, SSH keys, passwords
- File permissions: `600` for tfvars, private keys
- Authentication: bcrypt hashes only, SSH keys only (no password auth)
- Firewall: Ports 22, 80, 443 only
- SSL: Automatic Let's Encrypt certificates

## 🎯 Copilot Guidelines

1. **Configuration questions** → Reference `docs/configuration.md`
2. **Deployment issues** → Reference `docs/deployment.md` 
3. **Errors/problems** → Reference `docs/troubleshooting.md`
4. **First-time setup** → Reference `docs/quickstart.md` and `README.md`
5. **Code changes** → Follow modular structure (terraform/modules/*)
6. **Scripts** → Maintain interactive/validation features
7. **Documentation** → Keep generic (no hardcoded domains/names)

## ⚠️ Common Pitfalls

- Forgetting to run `validate-config.sh` before deployment
- Using wrong server type names (cx23 not CX22)
- Not waiting for DNS propagation (5-10 min)
- Missing `--local` flag for local backend
- Incorrect file permissions on tfvars (must be 600)
- Hardcoding values instead of using variables

## 📚 Additional Context

- Prices are approximate (user has discount)
- All examples use generic domains (yourdomain.com)
- Backend supports: local state (default), Terraform Cloud, S3
- DNS zone must exist in Hetzner DNS before deployment
- Services accessible after ~5-10 min (DNS + SSL propagation)
