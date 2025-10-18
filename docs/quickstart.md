# Quick Start Guide

Get your Docker Swarm infrastructure running on Hetzner Cloud in 5 minutes!

## Prerequisites Checklist

Before you begin, make sure you have:

- [ ] [Hetzner Cloud account](https://console.hetzner.cloud/) with API token
- [ ] [Hetzner DNS account](https://dns.hetzner.com/) with API token and zone configured
- [ ] Domain registered and DNS zone ID available
- [ ] Terraform >= 1.12 installed (for local deployment)
- [ ] Git installed
- [ ] SSH client installed

## Step 1: Clone Repository (30 seconds)

```bash
git clone https://github.com/YOUR_USERNAME/infrastructure.git
cd infrastructure
```

## Step 2: Generate Credentials (2 minutes)

### Generate SSH Keys

```bash
./scripts/utils/generate-ssh-keys.sh deploy ed25519
```

This creates:
- Private key: `~/.ssh/deploy_ed25519`
- Public key: `~/.ssh/deploy_ed25519.pub`

**Keep the private key secure and never commit it!**

### Generate Admin Password Hash

```bash
./scripts/utils/generate-password.sh admin
```

Enter a strong password when prompted. The script will output a bcrypt hash like:
```
admin:$2y$05$...
```

**Save this hash - you'll need it in the next step!**

## Step 3: Interactive Setup (2 minutes)

Run the interactive setup wizard:

```bash
./scripts/setup-env.sh dev
```

The script will prompt you for:

1. **Domain Configuration**
   - Main domain (e.g., `dev.example.com`)
   - Traefik dashboard hostname (e.g., `admin.dev.example.com`)
   - Swarmpit hostname (e.g., `swarmpit.dev.example.com`)
   - Dozzle hostname (e.g., `logs.dev.example.com`)
   - Let's Encrypt email

2. **Server Configuration**
   - Server name (e.g., `dev-server`)
   - Server type (recommended: `cx22` for dev)
   - Datacenter location (default: `nbg1`)

3. **Hetzner Credentials**
   - Hetzner Cloud API token
   - Hetzner DNS API token
   - DNS Zone ID

4. **SSH Configuration**
   - Path to SSH public key (or it will read the one generated in Step 2)
   - Path to SSH private key

5. **Admin Authentication**
   - Admin password hash (from Step 2)

The script creates a secure configuration file at `terraform/terraform.dev.tfvars`.

## Step 4: Validate Configuration (30 seconds)

```bash
./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars
```

This checks:
- ✓ All required fields are filled
- ✓ Domain and email formats are valid
- ✓ SSH keys are in correct format
- ✓ Password hash is bcrypt format
- ✓ File permissions are secure (600)

If validation passes, you're ready to deploy!

## Step 5: Deploy Infrastructure (1 minute setup + 5-10 minutes deployment)

```bash
./scripts/deploy-env.sh dev apply --local
```

The script will:
1. Validate your configuration
2. Initialize Terraform
3. Show you the deployment plan
4. Ask for confirmation
5. Deploy infrastructure to Hetzner Cloud

**Deployment includes:**
- 1 Hetzner Cloud server
- Docker Swarm initialization
- Traefik reverse proxy with SSL
- Swarmpit management UI
- Dozzle log viewer
- Automatic DNS records
- Firewall rules

## Step 6: Access Your Infrastructure (5-10 minutes after deployment)

After deployment completes, access your services:

### 🎯 Traefik Dashboard
```
https://admin.dev.example.com
```
Login: `admin` / `<your-password>`

**Features:**
- View all routing rules
- Monitor SSL certificates
- Check service health
- Real-time metrics

### 🐳 Swarmpit Management
```
https://swarmpit.dev.example.com
```
Login: `admin` / `<your-password>`

**Features:**
- Deploy Docker services
- Manage containers
- View resource usage
- Monitor node status

### 📊 Dozzle Logs
```
https://logs.dev.example.com
```
Login: `admin` / `<your-password>`

**Features:**
- Real-time container logs
- Multi-container streaming
- Search and filter
- Tail specific containers

### 🔐 SSH Access

Connect to your server:

```bash
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>
```

Get the server IP from outputs:
```bash
./scripts/deploy-env.sh dev output
```

## 🎉 Success!

You now have a fully functional Docker Swarm infrastructure!

## Next Steps

### Deploy Your First Application

1. **Create a Docker Compose file**

```yaml
version: '3.8'
services:
  web:
    image: nginx:latest
    deploy:
      labels:
        - traefik.enable=true
        - traefik.http.routers.web.rule=Host(`app.dev.example.com`)
        - traefik.http.services.web.loadbalancer.server.port=80
    networks:
      - traefik-public

networks:
  traefik-public:
    external: true
```

2. **Deploy via Swarmpit**
   - Go to Swarmpit → Stacks → Create Stack
   - Paste your compose file
   - Click Deploy

3. **Access your app**
   - Visit `https://app.dev.example.com`
   - SSL certificate is automatic!

### Add More Environments

```bash
# Setup staging
./scripts/setup-env.sh staging

# Setup production
./scripts/setup-env.sh prod

# Deploy staging
./scripts/deploy-env.sh staging apply --local

# Deploy production
./scripts/deploy-env.sh prod apply
```

### Monitor Your Infrastructure

```bash
# View outputs
./scripts/deploy-env.sh dev output

# Check Terraform state
cd terraform/
terraform show

# SSH to server
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>

# View Docker services
docker service ls

# View service logs
docker service logs traefik
docker service logs swarmpit
docker service logs dozzle
```

## Troubleshooting

### SSL Certificates Not Working

**Wait 5-10 minutes** after deployment for Let's Encrypt to issue certificates.

Check Traefik logs:
```bash
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>
docker service logs traefik | grep acme
```

Common issues:
- DNS not propagated yet
- Port 80/443 not accessible
- Invalid email address

### Services Not Accessible

Check service status:
```bash
ssh -i ~/.ssh/deploy_ed25519 root@<SERVER_IP>
docker service ls
docker service ps <service-name>
```

Check DNS:
```bash
dig +short admin.dev.example.com
```

Should return your server's IP address.

### "Permission Denied" Errors

Check SSH key permissions:
```bash
chmod 600 ~/.ssh/deploy_ed25519
chmod 644 ~/.ssh/deploy_ed25519.pub
```

### Configuration Validation Fails

Re-run with verbose output:
```bash
./scripts/utils/validate-config.sh terraform/terraform.dev.tfvars
```

Fix reported errors and re-validate.

## Clean Up

When you're done testing:

```bash
# Destroy infrastructure
./scripts/deploy-env.sh dev destroy --local

# Confirm by typing 'destroy'
```

This removes:
- Server
- DNS records
- All deployed services

**Note:** Terraform state files are kept for audit purposes.

## Getting Help

- **Documentation**: See `docs/` directory
- **Configuration Reference**: [configuration.md](configuration.md)
- **Deployment Guide**: [deployment.md](deployment.md)
- **Troubleshooting**: [troubleshooting.md](troubleshooting.md)
- **Issues**: GitHub Issues

---

**Next**: Read [configuration.md](configuration.md) for detailed variable explanations.
