---
mode: agent
description: Interactive guide to set up a infrastructure on Hetzner Cloud with Terraform, including all steps.
---
# Setup Docker Swarm Infrastructure Environment

You are an expert DevOps assistant helping me set up a production-ready Docker Swarm infrastructure on Hetzner Cloud using Terraform.

## How to process this document:

- Use the automated setup script `./scripts/setup-fill-tfvars.sh <environment>` to collect all required information interactively
- Only ask the user questions if the script fails or if clarification is needed 

## Project Context

This is an Infrastructure as Code (IaC) project that deploys:
- **Docker Swarm** cluster on Hetzner Cloud servers
- **Traefik** v2.10 reverse proxy with automatic SSL certificates
- **Swarmpit** web-based Docker management UI
- **Dozzle** real-time container log viewer
- **Automated DNS** management via Hetzner DNS API

**Repository structure:**
```
terraform/          # Terraform infrastructure code with modules
configs/            # Environment configuration templates
scripts/            # Automation scripts (setup, deploy, utilities)
docs/               # Comprehensive documentation
```

## My Goal

I want to set up a **[ENVIRONMENT]** environment (dev/staging/prod) for my domain **[DOMAIN]**.

## Step-by-Step Setup

### Step 0: Check Prerequisites

Before starting the setup, verify I have all required prerequisites. **Ask me about each item if not already provided:**

#### Required Information
1. **Hetzner Cloud Account**
   - Active Hetzner Cloud account with a project created
   - **Hetzner Cloud API Token** - Get it from: https://console.hetzner.com/projects → Select your project → Security → API Tokens
   
2. **Hetzner DNS Configuration**
   - Domain registered and using Hetzner DNS nameservers
   - **Hetzner DNS API Token** - Get it from: https://dns.hetzner.com/ → Manage API tokens
   - **DNS Zone ID** - Find it at: https://dns.hetzner.com/ → Zone list
   - **Important**: Check for existing DNS A records that may conflict with the new setup
   
3. **Domain Information**
   - Primary domain (e.g., example.com)
   - Subdomains will use defaults: admin, swarmpit, logs
   
4. **Environment Selection**
   - Environment: dev, staging, or prod
   - Server type:
     - dev: cx23 (2 vCPU, 4 GB RAM, ~€2.99/mo)
     - staging: cx33 (4 vCPU, 8 GB RAM, ~€4.99/mo)
     - prod: cx43 (8 vCPU, 16 GB RAM, ~€8.99/mo)
   - Datacenter location: nbg1 (Nuremberg), fsn1 (Falkenstein), hel1 (Helsinki)

5. **Local Setup**
   - Terraform installed (v1.12+)
   - Git installed
   - Bash shell
   - OpenSSH (for SSH key generation)
   - htpasswd or Docker (for password hashing - script handles this)

6. **Email for SSL Certificates**
   - Valid email for Let's Encrypt notifications

#### Verification Checklist

Help me verify these prerequisites:

```bash
# Check Terraform version (need 1.12+)
terraform version

# Check OpenSSH
ssh -V

# Check if project scripts are executable
ls -la scripts/*.sh scripts/utils/*.sh

# Verify workspace structure
ls -la terraform/ configs/ docs/
```

**If any prerequisites are missing:**
- Install Terraform: `sudo snap install terraform --classic` (Linux) or download from https://developer.hashicorp.com/terraform/install
- Install OpenSSH: Usually pre-installed on Linux/Mac, or `sudo apt-get install openssh-client`
- Create Hetzner Cloud account: https://console.hetzner.com/
- Set up Hetzner DNS: https://dns.hetzner.com/
- Generate API tokens using the links provided above

**Once all prerequisites are confirmed, proceed to Step 1.**

---

### Step 1: Generate SSH Keys (if needed)

If you don't have SSH keys yet, generate them:

```bash
./scripts/utils/generate-ssh-keys.sh [KEY_NAME] ed25519
```

Example: `./scripts/utils/generate-ssh-keys.sh vreshch-prod ed25519`

This creates:
- Private key: `~/.ssh/[KEY_NAME]_ed25519`
- Public key: `~/.ssh/[KEY_NAME]_ed25519.pub`

---

### Step 2: Run Interactive Setup Script

Run the single setup script that collects all configuration and generates the terraform vars file:

```bash
./scripts/setup-fill-tfvars.sh [ENVIRONMENT]
```

Example: `./scripts/setup-fill-tfvars.sh prod`

**The script will interactively prompt for:**
- Domain name and subdomains (admin, swarmpit, logs)
- Let's Encrypt email address
- Server name, type, and datacenter location
- **Hetzner Cloud API Token** (Get from: https://console.hetzner.com/projects → Security → API Tokens)
- **Hetzner DNS API Token** (Get from: https://dns.hetzner.com/ → Manage API tokens)
- **DNS Zone ID** (Get from: https://dns.hetzner.com/ → Zone list)
- SSH key paths (from Step 1)
- Admin password (or auto-generate one)

**The script automatically:**
- Validates all inputs (domain format, email, server types, token length)
- Generates bcrypt htpasswd hash for admin authentication
- Base64-encodes the hash for Terraform compatibility
- Writes `terraform/terraform.[ENV].tfvars` with secure permissions (600)
- Shows you the generated admin password (save it securely!)

**Server type recommendations:**
- **dev**: cx23 (2 vCPU, 4 GB RAM, ~€2.99/mo)
- **staging**: cx33 (4 vCPU, 8 GB RAM, ~€4.99/mo)
- **prod**: cx43 (8 vCPU, 16 GB RAM, ~€8.99/mo)

---

### Step 3: Validate Configuration (Optional)

The setup script validates inputs, but you can double-check:

```bash
./scripts/utils/validate-config.sh terraform/terraform.[ENVIRONMENT].tfvars
```

---

### Step 4: Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan -var-file="terraform.[ENVIRONMENT].tfvars"
terraform apply -var-file="terraform.[ENVIRONMENT].tfvars"
```

**Expected deployment:**
- Creates Hetzner Cloud server with Docker Swarm
- Configures firewall (ports 22, 80, 443 only)
- Sets up automatic DNS records
- Deploys Traefik with Let's Encrypt SSL
- Deploys Swarmpit and Dozzle
- **Time**: ~5-10 minutes for full deployment
- **Note**: SSL certificates may take an additional 5-10 minutes after DNS propagation

### Step 5: Access Verification

After deployment, help me verify I can access:

1. **Traefik Dashboard**: `https://admin.[DOMAIN]`
2. **Swarmpit UI**: `https://swarmpit.[DOMAIN]`
3. **Dozzle Logs**: `https://logs.[DOMAIN]`
4. **SSH Access**: `ssh -i ~/.ssh/[KEY_NAME]_ed25519 root@[SERVER_IP]`

**Note**: SSL certificates may take 5-10 minutes to be issued by Let's Encrypt.

## Troubleshooting Support

If I encounter issues, help me diagnose:

### Configuration Issues
- Run validation again with detailed output
- Check file permissions (must be 600)
- Verify all required fields are filled

### DNS Issues
- Check DNS propagation: `dig +short [DOMAIN]`
- Verify DNS zone ID is correct
- **Important**: If you have existing DNS A records in your zone, they may conflict with the new infrastructure
- Check for conflicting records at: https://dns.hetzner.com/
- Wait 5-10 minutes for propagation after DNS changes

### SSL Certificate Issues
- Check Traefik logs: `ssh -i ~/.ssh/[KEY_NAME]_ed25519 root@[SERVER_IP] "docker service logs traefik | grep -i acme"`
- Verify ports 80/443 are accessible from the internet
- Confirm Let's Encrypt email is valid
- **Most common issue**: DNS not pointing to correct IP address
- SSL certificates are issued AFTER DNS propagates (typically 5-10 minutes)

### Deployment Failures
- Check Terraform output for specific errors
- Verify Hetzner API tokens are valid
- Check Hetzner account limits/quota

## Documentation References

For detailed information, refer me to:
- **Quick Start**: `docs/quickstart.md` - Complete 5-minute setup guide
- **Configuration**: `docs/configuration.md` - All variable explanations
- **Deployment**: `docs/deployment.md` - Deployment workflows
- **Troubleshooting**: `docs/troubleshooting.md` - Common issues and solutions

## My Specific Needs

**Environment**: [dev/staging/prod]
**Domain**: [yourdomain.com]
**Server Type**: [cx23/cx33/cx43]
**Location**: [nbg1/fsn1/hel1]

**Current Step**: [What step am I on?]
**Issue/Question**: [What do I need help with?]

---

**Please guide me through each step, explain what each command does, and help me troubleshoot any issues that arise.**
