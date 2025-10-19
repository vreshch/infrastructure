# Infrastructure Destruction Guide

How to safely destroy your Docker Swarm infrastructure on Hetzner Cloud.

## ⚠️ Critical Warning

**IRREVERSIBLE ACTION**: All server data will be permanently lost.

**Gets destroyed**: Server, DNS records, Docker containers, volumes, SSL certificates, all data  
**Survives**: Local configs (`terraform/*.tfvars`), SSH keys, scripts

**Production**: Backup critical data, notify users before destroying!

## Destroy Commands

```bash
# Development
./scripts/deploy-env.sh dev destroy --local

# Staging
./scripts/deploy-env.sh staging destroy --local

# Production (⚠️ BACKUP FIRST!)
./scripts/deploy-env.sh prod destroy --local
```

Type `destroy` when prompted to confirm.

## What Gets Destroyed vs Survives

**Destroyed** (cloud resources):
- Hetzner Cloud server (VM + all data)
- DNS records (A/CNAME, DNS zone preserved)
- Docker Swarm cluster + all services
- Traefik, Swarmpit, Dozzle
- All volumes, containers, logs

**Survives** (local files):
- Configuration files (`terraform/*.tfvars`)
- SSH keys (`~/.ssh/deploy_ed25519*`)
- Scripts and documentation
- Terraform state (local backend)
- Hetzner API tokens
- Admin password hash

## Troubleshooting

### Server Locked Error
```bash
# Wait and retry
sleep 30
terraform destroy -var-file="terraform.dev.tfvars"
```

### DNS Zone Not Found
```bash
# Skip DNS, destroy compute only
cd terraform
terraform destroy -target=module.compute -var-file="terraform.dev.tfvars"
```

### Timeout Error
```bash
# Retry with refresh
cd terraform
terraform destroy -var-file="terraform.dev.tfvars" -refresh=true
```

### State Lock Error
```bash
# Remove lock file
rm -f terraform/.terraform.tfstate.lock.info
terraform destroy -var-file="terraform.dev.tfvars"
```

### Partial Destruction Failed
```bash
# Check state and retry
cd terraform
terraform show
terraform destroy -var-file="terraform.dev.tfvars"

# If still failing, manually delete via Hetzner Console
# Then: terraform state rm <resource_address>
```

### Force Destroy (Emergency Only)
```bash
cd terraform
terraform destroy -var-file="terraform.dev.tfvars" -auto-approve
```
**⚠️ No confirmation prompt!**

## Redeploy After Destruction

```bash
# Configs still exist - just redeploy
./scripts/deploy-env.sh dev apply --local
```

---

**See also**: `docs/deployment.md` | `docs/troubleshooting.md` | `docs/quickstart.md`
