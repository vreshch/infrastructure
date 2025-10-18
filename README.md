# 📚 Infrastructure Documentation - Table of Contents

## 🎯 Overview

This documentation provides a complete guide for deploying **production-ready Docker Swarm infrastructure** on Hetzner Cloud using **GitHub Actions**. The setup supports multiple environments (dev, staging, production) with **zero local setup required**.

---

## 📖 Documentation Structure

### 1. **requirements.md** - Infrastructure Requirements ⭐

- Overview and purpose
- Multi-environment architecture
- Resource planning and costs
- Use cases and limitations
- Prerequisites checklist

**Read this first** to understand what you're building and what you need.

### 2. **github-actions-setup.md** - GitHub Actions Deployment Guide

- Complete GitHub Actions configuration
- Repository structure
- GitHub Secrets setup
- Environment configuration files
- Workflow creation
- Deployment and monitoring

**Core guide** for automated deployment via GitHub Actions.

### 3. **setup-guide.md** - Manual Setup Guide (Optional)

- Local Terraform installation
- Step-by-step manual deployment
- For debugging and local development only

**Only needed** for local debugging or if you prefer manual control.

---

## 🚀 Quick Start (5 Minutes)

### For GitHub Actions Deployment (Recommended)

```bash
# 1. Fork or clone infrastructure repository
git clone git@github.com:vreshch/infrastructure.git

# 2. Configure GitHub Secrets (via GitHub UI)
# - HETZNER_CLOUD_TOKEN
# - HETZNER_DNS_TOKEN
# - HETZNER_DNS_ZONE_ID_INFRA
# - SSH_PUBLIC_KEY
# - SSH_PRIVATE_KEY
# - ADMIN_PASSWORD_HASH

# 3. Create environment configuration
cp environments/dev.tfvars.example environments/dev.tfvars
# Edit with your domains and settings

# 4. Push to deploy
git checkout -b dev
git push origin dev

# 5. Watch GitHub Actions deploy everything!
# Go to: Actions tab → Infrastructure Deploy workflow
```

**That's it!** No local Terraform needed.

---

## 🏗️ Architecture At-a-Glance

### Multi-Environment Setup

```
GitHub Actions → Terraform
    ↓
┌─────────────┬─────────────┬─────────────┐
│ Development │   Staging   │ Production  │
│ (CX22 4GB)  │ (CX32 8GB)  │ (CX42 16GB) │
└─────────────┴─────────────┴─────────────┘
```

### Domain Structure

**Infrastructure Domain** (Management Tools):

- `admin.dev.infra.io` - Traefik dashboard
- `swarmpit.dev.infra.io` - Docker Swarm UI
- `logs.dev.infra.io` - Container logs

**Application Domain** (Your Apps):

- `mysite.io` - Your deployed application
- `api.mysite.io` - API endpoints
- `www.mysite.io` - Website

---

## 📋 Key Concepts

### Separation of Concerns

| Aspect               | Infrastructure Domain       | Application Domain          |
| -------------------- | --------------------------- | --------------------------- |
| **Purpose**          | Management & monitoring     | Your application            |
| **Example**          | `dev.infra.io`              | `mysite.io`                 |
| **DNS Management**   | Automatically via Terraform | Points to infra server      |
| **SSL Certificates** | Auto via Traefik            | Auto via Traefik            |
| **Access**           | Admin password protected    | Public or app-specific auth |

### Multi-Environment Strategy

```
Development (dev.infra.io)
  ↓ Push to dev branch
  ↓ Test and verify

Staging (staging.infra.io)
  ↓ Merge dev → staging
  ↓ Pre-production testing

Production (prod.infra.io)
  ↓ Tag release / merge to main
  ↓ Live production site
```

---

## 💰 Cost Breakdown

### Example: 3 Environments

```
Environment      Server Type   Monthly Cost   Purpose
─────────────────────────────────────────────────────
Development      CX22 (4GB)    €8.21         Testing
Staging          CX32 (8GB)    €16.59        Pre-prod
Production       CX42 (16GB)   €32.75        Live site
+ DNS Zones      2 zones       €2.00         Domains
─────────────────────────────────────────────────────
Total Monthly:                 €59.55
```

### Cost Optimization

- **Development**: Destroy when not in use (save €8.21/month)
- **2 Environments**: Skip staging, use only dev + prod (save €16.59/month)
- **Minimal Setup**: Single CX22 for small projects (€9.21/month total)

---

## 🛠️ What You Need

### Required (One-Time Setup)

✅ GitHub account  
✅ Hetzner Cloud account  
✅ Hetzner DNS account  
✅ 2 domains registered:

- Infrastructure domain (e.g., `infra.io`)
- Application domain (e.g., `mysite.io`)
  ✅ 30-45 minutes for initial setup

### NOT Required

❌ Local Terraform installation  
❌ Local development environment  
❌ DevOps expertise  
❌ Complex networking knowledge

**Everything runs in GitHub Actions!**

---

## 📚 Document Reading Order

### For First-Time Setup

1. **requirements.md** - Understand the architecture (10 min read)
2. **github-actions-setup.md** - Follow step-by-step (30 min setup)
3. **Push code → Done!**

### For Troubleshooting

1. Check GitHub Actions logs (Actions tab)
2. See **github-actions-setup.md** → Troubleshooting section
3. See **setup-guide.md** → Manual debugging (if needed)

### For Maintenance

1. Update environment files (`environments/*.tfvars`)
2. Push changes → GitHub Actions automatically applies
3. Monitor via Swarmpit (`swarmpit.{env}.infra.io`)

---

## 🎓 Learning Path

### Beginner (Just Getting Started)

```
1. Read: requirements.md (architecture overview)
2. Follow: github-actions-setup.md (step-by-step)
3. Deploy: Push to dev branch
4. Verify: Access management tools
5. Learn: Explore Swarmpit and Traefik dashboards
```

### Intermediate (Ready to Deploy Apps)

```
1. Infrastructure deployed ✅
2. Create application Docker Compose file
3. Point your app domain to infra server
4. Deploy via Docker stack deploy
5. Traefik auto-configures SSL and routing
```

### Advanced (Multiple Projects)

```
1. One infrastructure repo per project
2. Shared infrastructure for multiple apps
3. Custom Traefik routing rules
4. Advanced monitoring and alerting
5. Backup and disaster recovery strategies
```

---

## 🚦 Success Criteria

After following the guides, you should have:

✅ GitHub Actions workflows configured  
✅ Infrastructure deploying automatically  
✅ Multiple environments (dev, staging, prod)  
✅ Management tools accessible via HTTPS  
✅ SSL certificates auto-generated  
✅ Ready to deploy applications

**Access your infrastructure:**

- Traefik: `https://admin.dev.infra.io`
- Swarmpit: `https://swarmpit.dev.infra.io`
- Dozzle: `https://logs.dev.infra.io`

---

## 🔄 Common Workflows

### Deploying New Environment

```bash
# 1. Create environment config
cp environments/dev.tfvars environments/staging.tfvars
vim environments/staging.tfvars  # Edit settings

# 2. Push to staging branch
git checkout -b staging
git push origin staging

# 3. GitHub Actions deploys automatically
```

### Updating Server Size

```bash
# 1. Edit environment file
nano environments/prod.tfvars
# Change: server_type = "cx52"  # Upgrade to 32GB

# 2. Commit and push
git add environments/prod.tfvars
git commit -m "feat: upgrade production to CX52"
git push origin main

# 3. GitHub Actions applies changes (brief downtime)
```

### Destroying Environment

```bash
# Via GitHub Actions UI:
# 1. Go to Actions → Destroy Infrastructure
# 2. Click "Run workflow"
# 3. Select environment: dev
# 4. Type "destroy" to confirm
# 5. Run workflow

# Resources deleted, billing stops
```

---

## 🆘 Getting Help

### Documentation

- **requirements.md** - Architecture and concepts
- **github-actions-setup.md** - Deployment guide
- **setup-guide.md** - Manual setup (debugging)

### Resources

- [Hetzner Cloud Docs](https://docs.hetzner.com/cloud/)
- [Hetzner DNS Docs](https://dns.hetzner.com/api-docs)
- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
- [Traefik Docs](https://doc.traefik.io/traefik/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)

### Common Issues

| Issue                | Solution                      | Reference                                 |
| -------------------- | ----------------------------- | ----------------------------------------- |
| GitHub Actions fails | Check secrets configuration   | github-actions-setup.md → Troubleshooting |
| DNS not resolving    | Wait 5-10 min for propagation | requirements.md → DNS Management          |
| SSL errors           | Check Traefik logs in Dozzle  | github-actions-setup.md → Monitoring      |
| High costs           | Destroy unused environments   | requirements.md → Cost Optimization       |

---

## 📦 Template Files Included

This repository includes:

```
docs/
├── requirements.md              # Architecture and requirements
├── github-actions-setup.md      # GitHub Actions deployment
└── setup-guide.md               # Manual setup (optional)

infrastructure/                  # Terraform files (copy to your repo)
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── modules/
    ├── compute/
    └── dns/

.github/workflows/               # GitHub Actions (copy to your repo)
├── infrastructure-deploy.yml
├── infrastructure-plan.yml
└── infrastructure-destroy.yml

environments/                    # Environment configs (copy to your repo)
├── dev.tfvars.example
├── staging.tfvars.example
└── prod.tfvars.example

README.md                    # This file (start here)
```

---

## 🎯 Next Steps

1. **Read** `requirements.md` to understand the architecture
2. **Follow** `github-actions-setup.md` for automated deployment
3. **Deploy** your first environment in 30 minutes
4. **Enjoy** your production-ready infrastructure!

**Happy deploying!** 🚀
