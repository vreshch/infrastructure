# Deployment Guide

Complete guide to deploying and managing your Docker Swarm infrastructure.

## Table of Contents

- [Deployment Methods](#deployment-methods)
- [Local Deployment](#local-deployment)
- [Terraform Cloud Deployment](#terraform-cloud-deployment)
- [Multi-Environment Workflow](#multi-environment-workflow)
- [Post-Deployment Steps](#post-deployment-steps)
- [Updating Infrastructure](#updating-infrastructure)
- [Destroying Infrastructure](#destroying-infrastructure)

## Deployment Methods

This infrastructure supports two deployment methods:

1. **Local Backend** - State stored locally (default, recommended for getting started)
2. **Terraform Cloud** - State stored in Terraform Cloud (recommended for teams)

## Local Deployment

### Prerequisites

- Terraform >= 1.12 installed
- Configuration file created (see [quickstart.md](quickstart.md))
- Configuration validated

### Quick Deployment

```bash
# Deploy with validation
./scripts/deploy-env.sh dev apply --local
```

This script:
1. ✓ Validates configuration
2. ✓ Initializes Terraform
3. ✓ Shows deployment plan
4. ✓ Asks for confirmation
5. ✓ Deploys infrastructure
6. ✓ Displays outputs

### Step-by-Step Deployment

#### 1. Validate Configuration

```bash
./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars
```

Expected output:
```
✅ SUCCESS: No errors or warnings found.
```

#### 2. Initialize Terraform

```bash
cd terraform/
terraform init
```

This downloads provider plugins and prepares the working directory.

#### 3. Preview Changes (Plan)

```bash
terraform plan -var-file="terraform.dev.tfvars"
```

Review the plan carefully:
- Resources to be created
- No unexpected deletions
- Correct configuration values

#### 4. Apply Changes

```bash
terraform apply -var-file="terraform.dev.tfvars"
```

Type `yes` when prompted to confirm deployment.

#### 5. Save Outputs

```bash
terraform output > deployment-info.txt
```

## Terraform Cloud Deployment

### Setup

1. **Create Terraform Cloud Account**
   - Go to [app.terraform.io](https://app.terraform.io/)
   - Create organization
   - Create workspace for each environment

2. **Configure Backend**

   Edit `terraform/versions.tf`:
   ```hcl
   terraform {
     cloud {
       organization = "YOUR_ORGANIZATION"
       workspaces {
         name = "infrastructure-dev"
       }
     }
   }
   ```

3. **Authenticate**

   ```bash
   terraform login
   ```

4. **Set Variables in Terraform Cloud**
   - Go to Workspace → Variables
   - Add all variables from your `.tfvars` file
   - Mark sensitive variables (tokens, keys, passwords)

### Deploy with Terraform Cloud

```bash
# Initialize with cloud backend
cd terraform/
terraform init

# Deploy
terraform apply
```

State is stored remotely and shared with team members.

## Multi-Environment Workflow

### Recommended Structure

```
environments/
├── dev
│   ├── Ready to deploy
│   └── Can destroy frequently
├── staging
│   ├── Test before production
│   └── Keep running for QA
└── prod
    ├── Production workload
    └── High availability setup
```

### Development Workflow

```bash
# 1. Setup dev environment
./scripts/setup-env.sh dev

# 2. Deploy to dev
./scripts/deploy-env.sh dev apply --local

# 3. Test changes
# Access services, verify functionality

# 4. Destroy when done
./scripts/deploy-env.sh dev destroy --local
```

### Staging Workflow

```bash
# 1. Setup staging
./scripts/setup-env.sh staging

# 2. Deploy to staging
./scripts/deploy-env.sh staging apply --local

# 3. Full testing
# - Performance testing
# - Integration testing
# - SSL certificate verification

# 4. Keep running for QA
# Don't destroy until testing complete
```

### Production Workflow

```bash
# 1. Setup production (with Terraform Cloud recommended)
./scripts/setup-env.sh prod

# 2. Review configuration
./scripts/utils/validate-config.sh terraform/terraform.prod.tfvars

# 3. Plan deployment
./scripts/deploy-env.sh prod plan

# 4. Deploy to production (requires 'yes' confirmation)
./scripts/deploy-env.sh prod apply

# 5. Verify deployment
./scripts/deploy-env.sh prod output

# 6. Test services
curl -I https://admin.example.com
```

## Post-Deployment Steps

### 1. Verify DNS Resolution

```bash
# Check all DNS records
dig +short yourdomain.com
dig +short admin.yourdomain.com
dig +short swarmpit.yourdomain.com
dig +short logs.yourdomain.com
```

All should return your server's IP address.

### 2. Wait for SSL Certificates

Let's Encrypt needs 5-10 minutes to issue certificates.

Check status:
```bash
# Get server IP from outputs
SERVER_IP=$(./scripts/deploy-env.sh dev output | grep server_public_ip | cut -d'"' -f2)

# SSH to server
ssh -i ~/.ssh/deploy_ed25519 root@$SERVER_IP

# Check Traefik logs
docker service logs traefik | grep acme
```

### 3. Test Services

```bash
# Test HTTPS access
curl -I https://admin.yourdomain.com

# Expected: HTTP/2 200 with basic auth requirement
```

### 4. Login to Management Tools

Visit each service and verify login:
- Traefik: `https://admin.yourdomain.com`
- Swarmpit: `https://swarmpit.yourdomain.com`
- Dozzle: `https://logs.yourdomain.com`

Login: `admin` / `<your-password>`

### 5. Verify Docker Swarm

```bash
# SSH to server
ssh -i ~/.ssh/deploy_ed25519 root@$SERVER_IP

# Check swarm status
docker node ls

# Check services
docker service ls

# Expected output:
# ID      NAME       MODE      REPLICAS   IMAGE           PORTS
# xxx     traefik    global    1/1        traefik:v2.10
# xxx     swarmpit   replicated 1/1        swarmpit:latest
# xxx     dozzle     global    1/1        amir20/dozzle
```

## Updating Infrastructure

### Update Configuration

```bash
# 1. Edit configuration
nano terraform/terraform.dev.tfvars

# 2. Validate changes
./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars

# 3. Preview changes
./scripts/deploy-env.sh dev plan --local

# 4. Apply changes
./scripts/deploy-env.sh dev apply --local
```

### Common Updates

#### Scale Server Size

```hcl
# Change from CX22 to CX32
server_type = "cx32"
```

**Note**: This will recreate the server (downtime expected).

#### Add DNS Records

```hcl
additional_cname_records = [
  {
    name   = "api"
    target = "${var.domain_name}."
  }
]
```

**Note**: DNS changes are non-destructive.

#### Change Domain

```hcl
domain_name   = "new.example.com"
traefik_host  = "admin.new.example.com"
swarmpit_host = "swarmpit.new.example.com"
dozzle_host   = "logs.new.example.com"
```

**Note**: Requires DNS zone configuration first.

### Zero-Downtime Updates

For production, use blue-green deployment:

1. Deploy new environment (prod-blue)
2. Test new environment
3. Switch DNS to new environment
4. Destroy old environment (prod-green)

## Destroying Infrastructure

### Destroy Single Environment

```bash
# Destroy with confirmation
./scripts/deploy-env.sh dev destroy --local
```

You must type `destroy` to confirm.

### What Gets Destroyed

- ✓ Hetzner Cloud server
- ✓ DNS records
- ✓ All deployed services
- ✓ SSL certificates
- ⚠️ Terraform state (kept for audit)

### What Doesn't Get Destroyed

- SSH keys (local files)
- Hetzner API tokens
- DNS zones (only records are removed)
- Local configuration files

### Before Destroying Production

**Checklist:**
- [ ] Backup all data
- [ ] Export application data
- [ ] Download SSL certificates (if needed)
- [ ] Document current configuration
- [ ] Notify team/users
- [ ] Plan migration if needed

### Emergency Destroy

If deployment fails and you need to start over:

```bash
# Force destroy
cd terraform/
terraform destroy -var-file="terraform.dev.tfvars" -auto-approve

# Clean state
rm -rf .terraform/ .terraform.lock.hcl terraform.tfstate*

# Start fresh
terraform init
```

## Deployment Troubleshooting

### Terraform Init Fails

**Error**: Provider not found

**Solution**:
```bash
cd terraform/
rm -rf .terraform/ .terraform.lock.hcl
terraform init
```

### Terraform Plan Shows Unwanted Changes

**Error**: Plan shows resources being destroyed

**Solution**:
1. Review what changed in configuration
2. Check Terraform state
3. If incorrect, don't apply!
4. Fix configuration first

### Apply Fails - Server Creation Error

**Error**: "Server type not available in location"

**Solution**:
1. Check available server types:
   ```bash
   curl https://api.hetzner.cloud/v1/server_types
   ```
2. Change `server_type` or `location` in config

### Apply Fails - DNS Error

**Error**: "Zone not found" or "Invalid zone ID"

**Solution**:
1. Verify DNS zone exists in Hetzner DNS
2. Check zone ID is correct
3. Verify DNS API token has correct permissions

### SSL Certificates Not Generating

**Error**: Services accessible but no HTTPS

**Wait**: 5-10 minutes for Let's Encrypt

**Debug**:
```bash
ssh -i ~/.ssh/deploy_ed25519 root@$SERVER_IP
docker service logs traefik | grep acme | tail -50
```

**Common Causes**:
- DNS not propagated yet
- Port 80 blocked
- Invalid email address
- Rate limit hit (if testing repeatedly)

### Services Not Starting

**Error**: Docker services in "Pending" state

**Debug**:
```bash
ssh -i ~/.ssh/deploy_ed25519 root@$SERVER_IP
docker service ls
docker service ps <service-name>
```

**Common Causes**:
- Image pull failure (check internet connectivity)
- Resource constraints (too small server)
- Configuration errors in deploy script

## Best Practices

### Development
- ✓ Destroy when not in use
- ✓ Use smallest server type
- ✓ Test all changes here first
- ✓ Keep state local

### Staging
- ✓ Mirror production configuration
- ✓ Keep running for QA
- ✓ Use Terraform Cloud for state
- ✓ Document test procedures

### Production
- ✓ Use Terraform Cloud
- ✓ Require approval for changes
- ✓ Enable backups
- ✓ Monitor constantly
- ✓ Document disaster recovery
- ✓ Never destroy without backup

## Next Steps

- **Manage Applications**: Deploy your first Docker service
- **Monitor**: Setup monitoring and alerting
- **Backup**: Configure backup strategy
- **Scale**: Add more nodes to swarm

---

**Need Help?** See [troubleshooting.md](troubleshooting.md) or open a GitHub Issue.
